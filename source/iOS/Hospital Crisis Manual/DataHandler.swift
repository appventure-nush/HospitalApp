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
        //Internal
        private var _title: String
        private var _cachedFormattedTitle: NSAttributedString?
        private var _markdownContents: String
        private var _cachedFormattedContents: NSAttributedString?
        
        /// - Returns: Heading string of this section. If this section has a header `# Heading`, the heading string would be `"#"`.
        public let headingStr: String
        /// - Returns: Heading level of this section. A heading level of 1 is equivalent to `# Heading`.
        public var headingLevel: Int {
            return headingStr.count
        }
        
        /// - Returns: The title of the section in markdown as plain text, without heading (`#`).
        public var title: String {
            return formattedTitle?.string.trimmingCharacters(in: .whitespacesAndNewlines) ?? _title
        }
        /// - Returns: The title of the section (assumed to be originally in markdown) as an `NSAttributedString`.
        public var formattedTitle: NSAttributedString? {
            if _title.isEmpty { return NSAttributedString() }
            if _cachedFormattedTitle == nil {
                _cachedFormattedTitle = try?
                               Down(markdownString:
                                   (headingStr + " " + _title).trimmingCharacters(in: .whitespacesAndNewlines)
                               ).toAttributedString()
            }
            
            return _cachedFormattedTitle
        }
    
        /// - Returns: The contents of this section in markdown as plain text.
        public var markdownContents: String {
            return _markdownContents
        }
        /// - Returns: The contents of the section as `NSAttributedString`.
        public var formattedContents: NSAttributedString? {
            if _cachedFormattedTitle == nil {
                _cachedFormattedContents = try?
                    Down(markdownString: markdownContents).toAttributedString()
            }
            return _cachedFormattedContents
        }
        
        /// - Returns: The  entire section, including title and contents, in markdown as plain text.
        public func asMarkdown() -> String {
            return
                (headingStr + " " + _title).trimmingCharacters(in: .whitespacesAndNewlines) +
                "\n\n" +
                _markdownContents
        }
        
        /// - Returns: The  entire section, including title and contents, as `NSAttributedString`.
        public func asAttributedString() -> NSAttributedString? {
            let newMarkdown = asMarkdown()
            return try? Down(markdownString: newMarkdown).toAttributedString()
        }
        
        ///Initialise a new Section with a `title` and its `markdownContents`. Optionally, `headingLevel` can be specified, which defaults
        ///
        ///  - Parameter title: The title of the section formatted in markdown.
        ///  - Parameter markdownContents: The contents of the section formatted in markdown.
        ///  - Parameter headingLevel: (Optional) the heading level of this section. Defaults to `1`, which is parsed as`<h1>Heading</h1>` or `# Heading`, and cannot be less than `0`.
        ///
        public init(title: String = "", markdownContents: String, headingLevel: Int? = nil) {
            self._title = title
            self._markdownContents = markdownContents
            if let headingLevel = headingLevel {
                var _headingStr = ""
                if headingLevel >= 1 {
                    for _ in 1...headingLevel {
                        _headingStr += "#"
                    }
                }
                self.headingStr = _headingStr
            } else {
                self.headingStr = "#"
            }
        }
        
        fileprivate var _subsections: [Section] = []
        /// - Returns: All subsections in this section, if converted via the `convertToSubsections()` method.
        public var subsections: [Section] {
            return _subsections
        }
        
        ///Converts any non-top level content to `Section` objects, accessible via the `subsections` variable. `subsections` is only available for use after this method is called.
        public func convertToSubsections() {
            var remainingContents = ""
            var tmp_title : String?
            var tmp_contents : String?
            
            //Insert to list of subsections helper function
            func insert() {
                if let t = tmp_title, let c = tmp_contents {
                    _subsections.append(
                        Section(title: t,
                                 markdownContents: c.trimmingCharacters(in: .whitespacesAndNewlines),
                                 headingLevel: headingLevel + 1
                        )
                    )
                }
            }
            
            //Data splitting based on heading level.
            for line in markdownContents.split(separator: "\n") {
                if line
                    .trimmingCharacters(in: .whitespacesAndNewlines)
                    .starts(with: headingStr + "# ") {
                    
                    insert()
                    tmp_title = String(line)
                    for _ in 1...(headingLevel + 1) {
                        tmp_title = String(tmp_title!.dropFirst())
                    }
                    tmp_title = tmp_title!.trimmingCharacters(in: .whitespacesAndNewlines)
                    
                    tmp_contents = ""
                } else if tmp_contents != nil {
                    tmp_contents! += line + "\n"
                } else {
                    remainingContents += line + "\n"
                }
            }
            insert()
            
            //Only remains that aren't in a category will be saved in the markdownContents variable
            _markdownContents = remainingContents
        }
    }
    
    
    private var _rawContents: String
    private var _sectionList: [Section] = []
    public var sectionList: [Section] {
        return _sectionList
    }
    
    public init?(rawContents: String) {
        guard let sectionList = DataHandler.parseRawContentsIntoSections(rawContents) else {return nil}
        _rawContents = rawContents
        _sectionList = sectionList
    }
    
    public class func parseRawContentsIntoSections(_ rawContents: String) -> [Section]? {
        let topLevel = Section(markdownContents: rawContents, headingLevel: 0)
        
        topLevel.convertToSubsections()
        if topLevel.subsections.count > 0 {
            return topLevel.subsections
        } else {
            return nil
        }
    }
}
