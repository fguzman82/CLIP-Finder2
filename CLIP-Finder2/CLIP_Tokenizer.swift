//
//  CLIP_Tokenizer.swift
//  CLIP-Finder2
//
//  Created by Fabio Guzman on 26/06/24.
// This is a Swift version adapted from
// https://github.com/mlfoundations/open_clip/blob/main/src/open_clip/tokenizer.py
//

import Foundation

struct BytePair: Hashable {
    let a: String
    let b: String
    init(_ a: String, _ b: String) {
        self.a = a
        self.b = b
    }
    init(tuple: [String]) {
        self.a = tuple[0]
        self.b = tuple[1]
    }

    static func == (lhs: BytePair, rhs: BytePair) -> Bool {
        return lhs.a == rhs.a && lhs.b == rhs.b
    }
    func hash(into hasher: inout Hasher) {
        hasher.combine(a)
        hasher.combine(b)
    }
}

class CLIPTokenizer {
    let bpeRanks: Dictionary<BytePair, Int>
    let verbose: Bool
    private let tokensToIds: [String: Int32]
    private let idsToTokens: [Int32: String]
    private let byteEncoder: [UInt8: String]
    private let byteDecoder: [String: UInt8]
    private var cache: [String: String]
    private let byteOrder: [UInt8]
    
    private static let byteEncodeRegex: NSRegularExpression = {
        let pattern = #"'s|'t|'re|'ve|'m|'ll|'d|\p{L}+|\p{N}+|[^\s\p{L}\p{N}]+"#
        return try! NSRegularExpression(pattern: pattern, options: [.caseInsensitive])
    }()

    static let shared = CLIPTokenizer()

    let startOfTextToken: String = "<start_of_text>"
    let endOfTextToken: String = "<end_of_text>"
    let contextLength: Int
    let vocabSize: Int32
    let allSpecialIds: [Int32]
    let sotTokenId: Int32
    let eotTokenId: Int32

    private static var defaultBPEPath: String = {
        guard let bpePath = Bundle.main.path(forResource: "bpe_simple_vocab_16e6", ofType: "txt") else {
            fatalError("No se pudo encontrar el archivo BPE en el bundle")
        }
        return bpePath
    }()

    private convenience init() {
        self.init(bpePath: CLIPTokenizer.defaultBPEPath)
    }

    init(bpePath: String, contextLength: Int = 77, verbose: Bool = false) {
        self.contextLength = contextLength
        self.verbose = verbose

        let bpeData = try! String(contentsOfFile: bpePath, encoding: .utf8)
        let merges = bpeData.components(separatedBy: .newlines)[1...49152-256-2]

        (self.byteEncoder, self.byteOrder) = CLIPTokenizer.bytesToUnicode()
        self.byteDecoder = Dictionary(uniqueKeysWithValues: self.byteEncoder.map { ($1, $0) })
        
        let initialVocab = CLIPTokenizer.createInitialVocab(byteEncoder: self.byteEncoder, byteOrder: self.byteOrder)
        var vocab = initialVocab
        vocab += vocab.map { $0 + "</w>" }
        vocab += merges.map { $0.replacingOccurrences(of: " ", with: "") }

        let specialTokens = [startOfTextToken, endOfTextToken]
        vocab += specialTokens

        self.tokensToIds = Dictionary(uniqueKeysWithValues: zip(vocab, (0..<vocab.count).map { Int32($0) }))
        self.idsToTokens = Dictionary(uniqueKeysWithValues: self.tokensToIds.map { ($1, $0) })

        var bpeRanks: Dictionary<BytePair, Int> = [:]
        for (i, item) in merges.enumerated() {
            let tuple = item.unicodeScalars.split(separator: " ", omittingEmptySubsequences: false).map { String($0) }
            let bp = BytePair(tuple: tuple)
            bpeRanks[bp] = i
        }
        self.bpeRanks = bpeRanks
        self.cache = Dictionary(uniqueKeysWithValues: specialTokens.map { ($0, $0) })

        self.vocabSize = Int32(self.tokensToIds.count)
        self.sotTokenId = self.tokensToIds[startOfTextToken]!
        self.eotTokenId = self.tokensToIds[endOfTextToken]!
        self.allSpecialIds = [sotTokenId, eotTokenId]
    }

    private static func bytesToUnicode() -> ([UInt8: String], [UInt8]) {
        var bs = Array(33...126) + Array(161...172) + Array(174...255)
        var cs = bs
        var n = 0
        
        for b in 0...255 {
            if !bs.contains(b) {
                bs.append(b)
                cs.append(256 + n)
                n += 1
            }
        }
        
        let dict = Dictionary(uniqueKeysWithValues: zip(bs.map { UInt8($0) }, cs.map { String(UnicodeScalar($0)!) }))
        
        return (dict, bs.map { UInt8($0) })
    }

    private func getPairs(word: [String]) -> Set<BytePair> {
        var s = Set<BytePair>()
        for i in 0..<word.count - 1 {
            let bp = BytePair(word[i], word[i + 1])
            s.insert(bp)
        }
        return s
    }

    private func cleanAndLowercase(_ text: String) -> String {
        let basicCleaned = text.trimmingCharacters(in: .whitespacesAndNewlines)
        
        let whitespacesCleaned = basicCleaned.components(separatedBy: .whitespacesAndNewlines)
            .filter { !$0.isEmpty }
            .joined(separator: " ")
        return whitespacesCleaned.lowercased()
    }
   
    func byteEncode(text: String) -> [String] {
        let pattern = #"'s|'t|'re|'ve|'m|'ll|'d|\p{L}+|\p{N}|\p{L}\p{N}+|[^\s\p{L}\p{N}]+"#
        let regex = try! NSRegularExpression(pattern: pattern, options: [.caseInsensitive])
        let matches = regex.matches(in: text, range: NSRange(text.startIndex..., in: text))
        let tokens = matches.map { String(text[Range($0.range, in: text)!]) }
        return tokens.map { token in
            token.utf8.map { byteEncoder[$0]! }.joined()
        }
    }
    
    func bpe(token: String) -> String {
        if let cachedToken = cache[token] {
            if verbose { print("Cache hit for token: \(token)") }
            return cachedToken
        }
        
        var word = Array(token).map(String.init)
        if word.last != "</w>" {
            word[word.count - 1] = word.last! + "</w>"
        }
        if verbose {
            print("Performing BPE on token: \(token)")
            print("Initial word: \(word)")
        }
        
        var pairs = Array(getPairs(word: word))
        
        if verbose { print("Initial pairs: \(pairs)") }
                
        while true {
            let bigrams = pairs.filter { bpeRanks[$0] != nil }
            if bigrams.isEmpty {
                break
            }
            let bigram = bigrams.min { bpeRanks[$0]! < bpeRanks[$1]! }!
            if verbose { print("Selected bigram: \(bigram)") }
            let first = bigram.a
            let second = bigram.b
            var newWord: [String] = []
            var i = 0
            while i < word.count {
                if let j = word[i...].firstIndex(of: first) {
                    newWord.append(contentsOf: word[i..<j])
                    i = j
                } else {
                    newWord.append(contentsOf: word[i...])
                    break
                }
                
                if i < word.count - 1 && word[i] == first && word[i + 1] == second {
                    newWord.append(first + second)
                    i += 2
                } else {
                    newWord.append(word[i])
                    i += 1
                }
            }
            word = newWord
            if verbose { print("Updated word: \(word)") }
            if word.count == 1 {
                break
            } else {
                pairs = Array(getPairs(word: word))
                if verbose { print("Updated pairs: \(pairs)") }
            }
        }
        
        let result = word.joined(separator: " ")
        cache[token] = result
        if verbose { print("BPE result: \(result)") }
        return result
    }

    func tokenize(text: String) -> [Int32] {
        let cleanedText = cleanAndLowercase(text)
        if verbose { print("Cleaned text: \(cleanedText)") }
        
        let byteTokens = byteEncode(text: cleanedText)
        if verbose { print("Byte tokens: \(byteTokens)") }
        
        var tokens: [Int32] = []
        for byteToken in byteTokens {
            let bpeResult = bpe(token: byteToken)
            
            let bpeTokens = bpeResult.split(separator: " ").map(String.init)
            if verbose { print("BPE tokens: \(bpeTokens)") }
            
            for token in bpeTokens {
                if let tokenId = tokensToIds[token] {
                    tokens.append(tokenId)
                    if verbose { print("Token: \(token), ID: \(tokenId)") }
                }
            }
        }
        return tokens
    }

    func tokenize(texts: [String]) -> [[Int32]] {
        return texts.map { text in
            var tokens = [sotTokenId] + tokenize(text: text) + [eotTokenId]
            if tokens.count > contextLength {
                tokens = Array(tokens.prefix(contextLength))
                tokens[contextLength - 1] = eotTokenId
            }
            return tokens + Array(repeating: 0, count: max(0, contextLength - tokens.count))
        }
    }

    func decode(tokens: [Int32]) -> String {
        let text = tokens.compactMap { idsToTokens[$0] }.joined()
        return text.utf8.compactMap { byteDecoder[String($0)] }
            .map { String(UnicodeScalar($0)) }
            .joined()
            .replacingOccurrences(of: "</w>", with: " ")
            .trimmingCharacters(in: .whitespaces)
    }
    
    private static func createInitialVocab(byteEncoder: [UInt8: String], byteOrder: [UInt8]) -> [String] {
        return byteOrder.map { byteEncoder[UInt8($0)]! }
    }
}




