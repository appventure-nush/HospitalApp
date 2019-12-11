//
//  DataHandler.swift
//  Hospital App iOS
//
//  Created by Lim Wern Jie on 06/12/2019.
//  Copyright © 2019 Wern Jie Lim. All rights reserved.
//

import Foundation
import Down

public class DataHandler {
    
    public class Section {
        fileprivate var _title: String
        fileprivate var _markdownContents: String
        
        public var title: String {
            return _title
        }
        public var markdownContents: String {
            return _markdownContents
        }
        public var formattedContents: NSAttributedString? {
            return try? Down(markdownString: markdownContents).toAttributedString()
        }
        
        
        public func asMarkdown() -> String {
            return "# " + _title + "\n\n" + _markdownContents
        }
        public func asAttributedString() -> NSAttributedString? {
            let newMarkdown = asMarkdown()
            return try? Down(markdownString: newMarkdown).toAttributedString()
        }
        
        fileprivate init(title: String, markdownContents: String) {
            self._title = title
            self._markdownContents = markdownContents
        }
    }
    
    public class Subtopic: Section {
        public override func asMarkdown() -> String {
            return "## " + _title + "\n\n" + _markdownContents
        }
    }
    public class Topic : Section {
        fileprivate var _subtopics: [Subtopic] = []
        public var subtopics: [Subtopic] {
            return _subtopics
        }
        fileprivate override init(title: String, markdownContents: String) {
            super.init(title: title, markdownContents: markdownContents)
        }
        
        public func convertToSubtopics() {
            var remainingContents = ""
            var tmp_title : String?
            var tmp_contents : String?
            func insert() {
                if let t = tmp_title, let c = tmp_contents {
                    _subtopics.append(
                        Subtopic(title: t,
                                 markdownContents: c.trimmingCharacters(in: .whitespacesAndNewlines)
                        )
                    )
                }
            }
            
            for line in markdownContents.split(separator: "\n") {
                if line.starts(with: "## ") {
                    insert()
                    tmp_title =
                        line
                        .dropFirst()
                        .dropFirst()
                        .trimmingCharacters(in: .whitespacesAndNewlines)
                    
                    tmp_contents = ""
                } else if tmp_contents != nil {
                    tmp_contents! += line + "\n"
                } else {
                    remainingContents += line + "\n"
                }
            }
            insert()
            
            _markdownContents = remainingContents
        }
    }
    
    
    private var _rawContents: String
    private var _topicList: [Topic] = []
    public var topicList: [Topic] {
        return _topicList
    }
    
    public init?(rawContents: String) {
        guard let topicList = DataHandler.parseRawContents(rawContents) else {return nil}
        _rawContents = rawContents
        _topicList = topicList
    }
    
    public class func parseRawContents(_ rawContents: String) -> [Topic]? {
        var list: [Topic] = []
        
        var tmp_title : String?
        var tmp_contents : String?
        func insert() {
            if let t = tmp_title, let c = tmp_contents {
                list.append(
                    Topic(title: t,
                             markdownContents: c.trimmingCharacters(in: .whitespacesAndNewlines)
                    )
                )
            }
        }
        
        for line in rawContents.split(separator: "\n") {
            if line.starts(with: "# ") {
                insert()
                tmp_title    =
                    line
                    .dropFirst()
                    .trimmingCharacters(in: .whitespacesAndNewlines)
                
                tmp_contents = ""
            } else if tmp_contents != nil {
                tmp_contents! += line + "\n"
            } else {
                return nil //No header detected.
            }
        }
        insert()
        
        
        return list
    }
}
