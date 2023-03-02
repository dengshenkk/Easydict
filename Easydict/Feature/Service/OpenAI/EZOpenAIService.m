//
//  EZOpenAIService.m
//  Easydict
//
//  Created by tisfeng on 2023/2/24.
//  Copyright © 2023 izual. All rights reserved.
//

#import "EZOpenAIService.h"
#import "EZTranslateError.h"
#import "EZQueryResult+EZDeepLTranslateResponse.h"

static NSString *kOpenAIURL = @"https://api.openai.com/v1/completions";

@interface EZOpenAIService ()


@end

@implementation EZOpenAIService

- (instancetype)init {
    if (self = [super init]) {
    }
    return self;
}


#pragma mark - 重写父类方法

- (EZServiceType)serviceType {
    return EZServiceTypeOpenAI;
}

- (NSString *)name {
    return NSLocalizedString(@"openai_translate", nil);
}

- (NSString *)link {
    return kOpenAIURL;
}

// Supported languages, key is EZLanguage, value is the same as the key.
- (MMOrderedDictionary<EZLanguage, NSString *> *)supportLanguagesDictionary {
    MMOrderedDictionary *orderedDict = [[MMOrderedDictionary alloc] init];
    
    NSArray<EZLanguage> *allLanguages = [EZLanguageManager allLanguages];
    for (EZLanguage language in allLanguages) {
        [orderedDict setObject:language forKey:language];
    }
    
    return orderedDict;
}

/// Use OpenAI to translate text.
- (void)translate:(NSString *)text from:(EZLanguage)from to:(EZLanguage)to completion:(void (^)(EZQueryResult *_Nullable, NSError *_Nullable))completion {
    NSArray *languages = @[ from, to ];
    if ([EZLanguageManager onlyContainsChineseLanguages:languages]) {
        [super translate:text from:from to:to completion:completion];
        return;
    }
    
    NSString *sourceLanguage = [self languageCodeForLanguage:from];
    NSString *targetLanguage = [self languageCodeForLanguage:to];
    
    BOOL isWord = [self isWord:text];
    if (isWord) {
        [self queryDict:text from:sourceLanguage to:targetLanguage completion:^(NSString *_Nullable result, NSError *_Nullable error) {
            if (error) {
                completion(self.result, error);
                return;
            }
            
            [self handleDefinitionAndEtymologyText:result completion:completion];
        }];
        return;
    }
    
    [self translateText:text from:sourceLanguage to:targetLanguage completion:^(NSString *_Nullable result, NSError *_Nullable error) {
        if (error) {
            completion(self.result, error);
            return;
        }
        
        self.result.normalResults = [[result trim] componentsSeparatedByString:@"\n"];
        completion(self.result, error);
    }];
}

- (void)translateText:(NSString *)text from:(NSString *)sourceLanguage to:(NSString *)targetLanguage completion:(void (^)(NSString *_Nullable, NSError *_Nullable))completion {
    /**
     [{
     “role”: “user”,
     “content”: "Translate the following English text to French: '{text}'"
     }]
     */
    
    // This prompt is genarated by ChatGPT, but it's not working well.
    //    NSString *prompt = [NSString stringWithFormat:@"Translate '%@' to %@:", text, targetLangCode, souceLangCode];
    NSString *prompt = [NSString stringWithFormat:@"translate from %@ to %@:\n%@ =>", sourceLanguage, targetLanguage, text];
    //   prompt = [NSString stringWithFormat:@"Translate the following %@ text to %@: '{%@}'", sourceLanguage, targetLanguage, text];
    NSDictionary *dict = @{
        @"role" : @"user",
        @"content" : prompt,
    };
    
    [self startChat:@[ dict ] completion:completion];
    
    //    [self startCompletion:prompt completion:completion];
}

- (void)queryDict:(NSString *)word from:(NSString *)sourceLanguage to:(NSString *)targetLanguage completion:(void (^)(NSString *_Nullable, NSError *_Nullable))completion {
    BOOL isWord = [self isWord:word];
    if (!isWord) {
        completion(@"", nil);
    }
    
    // // Look up word definition and etymology,
    
    // This is an English word: 'battery', look up its brief definition and detailed etymology, output strictly in the following format: '\n------\nDefinition: xxx\n------\nEtymology: xxx', answer in Chinese with a word count between between 100 and 300.
    NSString *prompt = [NSString stringWithFormat:@"This is an %@ word: '%@', look up its brief definition and detailed etymology, output strictly in the following format: '\n------\nDefinition: xxx\n------\nEtymology: xxx\n', answer in %@ with a word count between between 100 and 300.", sourceLanguage, word, targetLanguage];
    
    NSDictionary *dict = @{
        @"role" : @"user",
        @"content" : prompt,
    };
    
    [self startChat:@[ dict ] completion:completion];
    
    // ⚠️ It takes too long(>10s) to generate a result for text-davinci-003.
    //    [self startCompletion:prompt completion:completion];
}

/// Chat using gpt-3.5, response so quickly, generally less than 3s.
- (void)startChat:(NSArray<NSDictionary *> *)messages completion:(void (^)(NSString *_Nullable, NSError *_Nullable))completion {
    // Read openai key from NSUserDefaults
    NSString *openaiKey = [[NSUserDefaults standardUserDefaults] stringForKey:EZOpenAIKey] ?: @"";
    
    NSDictionary *header = @{
        @"Content-Type" : @"application/json",
        @"Authorization" : [NSString stringWithFormat:@"Bearer %@", openaiKey],
    };
    
    // Docs: https://platform.openai.com/docs/guides/chat/chat-vs-completions
    NSDictionary *body = @{
        @"model" : @"gpt-3.5-turbo",
        @"messages" : messages,
        @"temperature" : @(0),
        @"max_tokens" : @(1000),
        @"top_p" : @(1.0),
        @"frequency_penalty" : @(1),
        @"presence_penalty" : @(1),
    };
    
    NSMutableURLRequest *request = [[NSMutableURLRequest alloc] initWithURL:[NSURL URLWithString:@"https://api.openai.com/v1/chat/completions"]];
    request.HTTPMethod = @"POST";
    request.allHTTPHeaderFields = header;
    request.HTTPBody = [NSJSONSerialization dataWithJSONObject:body options:0 error:nil];
    
    NSURLSession *session = [NSURLSession sharedSession];
    NSURLSessionDataTask *task = [session dataTaskWithRequest:request completionHandler:^(NSData *_Nullable data, NSURLResponse *_Nullable response, NSError *_Nullable error) {
        if (error) {
            completion(nil, error);
            return;
        }
        
        NSError *jsonError;
        NSDictionary *json = [NSJSONSerialization JSONObjectWithData:data options:0 error:&jsonError];
        if (jsonError) {
            completion(nil, jsonError);
            return;
        }
        
        /**
         {
         'id': 'chatcmpl-6p9XYPYSTTRi0xEviKjjilqrWU2Ve',
         'object': 'chat.completion',
         'created': 1677649420,
         'model': 'gpt-3.5-turbo',
         'usage': {'prompt_tokens': 56, 'completion_tokens': 31, 'total_tokens': 87},
         'choices': [
         {
         'message': {
         'role': 'assistant',
         'content': 'The 2020 World Series was played in Arlington, Texas at the Globe Life Field, which was the new home stadium for the Texas Rangers.'},
         'finish_reason': 'stop',
         'index': 0
         }
         ]
         }
         */
        NSArray *choices = json[@"choices"];
        if (choices.count == 0) {
            NSError *error = [EZTranslateError errorWithString:@"no result."];
            /**
             may be return error json
             {
             "åerror" : {
             "code" : "invalid_api_key",
             "message" : "Incorrect API key provided: sk-5DJ2bQxdT. You can find your API key at https:\/\/platform.openai.com\/account\/api-keys.",
             "param" : null,
             "type" : "invalid_request_error"
             }
             }
             */
            if (json[@"error"]) {
                error = [EZTranslateError errorWithString:json[@"error"][@"message"]];
            }
            
            completion(nil, error);
            return;
        }
        
        NSString *result = choices[0][@"message"][@"content"];
        completion(result, nil);
    }];
    [task resume];
}

/// Completion, Ref: https://github.com/yetone/bob-plugin-openai-translator/blob/main/src/main.js and https://github.com/scosman/voicebox/blob/9f65744ef9182f5bfad6ed29ddcd811bd8b1f71e/ios/voicebox/Util/OpenApiRequest.m
- (void)startCompletion:(NSString *)prompt completion:(void (^)(NSString *_Nullable, NSError *_Nullable))completion {
    // Read openai key from NSUserDefaults
    NSString *openaiKey = [[NSUserDefaults standardUserDefaults] stringForKey:EZOpenAIKey] ?: @"";
    
    NSDictionary *header = @{
        @"Content-Type" : @"application/json",
        @"Authorization" : [NSString stringWithFormat:@"Bearer %@", openaiKey],
    };
    // Docs: https://platform.openai.com/docs/api-reference/completions
    NSDictionary *body = @{
        @"model" : @"text-davinci-003",
        @"prompt" : prompt,
        @"temperature" : @(0),
        @"max_tokens" : @(1000),
        @"top_p" : @(1.0),
        @"frequency_penalty" : @(1),
        @"presence_penalty" : @(1),
    };
    
    NSMutableURLRequest *request = [[NSMutableURLRequest alloc] initWithURL:[NSURL URLWithString:@"https://api.openai.com/v1/completions"]];
    request.HTTPMethod = @"POST";
    request.allHTTPHeaderFields = header;
    request.HTTPBody = [NSJSONSerialization dataWithJSONObject:body options:0 error:nil];
    
    NSURLSession *session = [NSURLSession sharedSession];
    NSURLSessionDataTask *task = [session dataTaskWithRequest:request completionHandler:^(NSData *_Nullable data, NSURLResponse *_Nullable response, NSError *_Nullable error) {
        if (error) {
            completion(nil, error);
            return;
        }
        
        NSError *jsonError;
        NSDictionary *json = [NSJSONSerialization JSONObjectWithData:data options:0 error:&jsonError];
        if (jsonError) {
            completion(nil, jsonError);
            return;
        }
        
        
        NSArray *choices = json[@"choices"];
        if (choices.count == 0) {
            NSError *error = [EZTranslateError errorWithString:@"no result."];
            /**
             may be return error json
             {
             "error" : {
             "code" : "invalid_api_key",
             "message" : "Incorrect API key provided: sk-5DJ2bQxdT. You can find your API key at https:\/\/platform.openai.com\/account\/api-keys.",
             "param" : null,
             "type" : "invalid_request_error"
             }
             }
             */
            if (json[@"error"]) {
                error = [EZTranslateError errorWithString:json[@"error"][@"message"]];
            }
            
            completion(nil, error);
            return;
        }
        
        NSString *result = choices[0][@"text"];
        completion(result, nil);
    }];
    [task resume];
}

- (void)ocr:(EZQueryModel *)queryModel completion:(void (^)(EZOCRResult *_Nullable, NSError *_Nullable))completion {
    NSLog(@"OpenAI not support ocr");
}


#pragma mark - Parse Definition and Etymology.

- (void)handleDefinitionAndEtymologyText:(NSString *)text completion:(void (^)(EZQueryResult *, NSError *_Nullable error))completion {
    __block NSString *definition, *etymology;
    [self parseDefinitionAndEtymologyFromText:text definition:&definition etymology:&etymology];
    [self handleDefinition:definition etymology:etymology completion:completion];
}

/// Parse Definition and Etymology from text.
- (void)parseDefinitionAndEtymologyFromText:(NSString *)text definition:(NSString **)definition etymology:(NSString **)etymology {
    /**
     "\n\n------\nDefinition: 电池，是一种用于储存能量的装置。它通常由多个单元连接而成，可以将化学能转换成电能并供应到相应的设备中。 \n------\nEtymology: battery 这个词最早出现在17c. 年代，来自法语batterie（“队列、行军”）和意大利语battere （“打击、敲打”）。它最初是一个军事术语，形容士兵们站在一行的样子。后来引伸出新的意思——尤其泛指使用武器对敌人进行集体攻击——然后又被引申为物理上的意义上去形容一系列相连的部件或者装置。"
     */
    
    NSString *definitionDelimiter = @"\n------\nDefinition: ";
    NSString *etymologyDelimiter = @"\n------\nEtymology: ";
    if ([text containsString:definitionDelimiter] && [text containsString:etymologyDelimiter]) {
        NSArray *components = [text componentsSeparatedByString:etymologyDelimiter];
        if (components.count > 1) {
            *etymology = [components[1] trim];
        }
        
        components = [components[0] componentsSeparatedByString:definitionDelimiter];
        
        if (components.count > 1) {
            *definition = [components[1] trim];
        }
    }
}

/// Handle Definition And Etymology
- (void)handleDefinition:(NSString *)definition etymology:(NSString *)etymology completion:(void (^)(EZQueryResult *, NSError *_Nullable error))completion {
    if (definition) {
        self.result.normalResults = @[ definition ];
    }
    
    if (etymology.length) {
        EZTranslateWordResult *wordResult = [[EZTranslateWordResult alloc] init];
        wordResult.etymology = etymology;
        self.result.wordResult = wordResult;
        self.result.queryText = self.queryModel.queryText;
    }
    
    completion(self.result, nil);
}

#pragma mark -

/// Check if text is a word.
- (BOOL)isWord:(NSString *)text {
    if (text.length > EZEnglishWordMaxLength) {
        return NO;
    }
    
    NSString *pattern = @"^[a-zA-Z]+$";
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"SELF MATCHES %@", pattern];
    return [predicate evaluateWithObject:text];
}

@end
