/*
 JHMatchInfo.h
 Copyright (C) 2012 Joe Hsieh
 
 Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:
 
 The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.
 
 THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
*/

#import <Foundation/Foundation.h>

typedef enum {
    notExist, // not exist
    justInserted, // added record after scan
    existing // exist
} MatchInfoRecordState;

@interface JHMatchInfo : NSObject<NSCopying, NSCoding, NSPasteboardWriting, NSPasteboardReading>
{
    NSString *key;
    NSString *translateString;
    NSString *comment;
    NSString *filePath;
    MatchInfoRecordState state;
}

@property (retain, nonatomic) NSString *key;
@property (retain, nonatomic) NSString *translateString;
@property (retain, nonatomic) NSString *comment;
@property (retain, nonatomic) NSString *filePath;

- (MatchInfoRecordState)state;
- (void)setState:(MatchInfoRecordState)state;

@end