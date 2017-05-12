//
//  ViewController.m
//  HttpsDemo
//
//  Created by Johnny on 2017/4/13.
//  Copyright © 2017年 Sogou. All rights reserved.
//

#import "ViewController.h"
#import "AFNetworking.h"
#import <AssertMacros.h>

@interface ViewController () <NSURLConnectionDelegate, NSURLConnectionDataDelegate, NSURLSessionDelegate, NSURLSessionDataDelegate>

@property (nonatomic, strong) IBOutlet UISegmentedControl *urlSegmented;
@property (nonatomic, strong) IBOutlet UISegmentedControl *credSegmented;

@property (nonatomic, strong) NSURLConnection *connection;
@property (nonatomic, strong) NSURLSession *session;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
}


- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)printLogWithTitle:(NSString *)title content:(id)content {
    NSString *logSeparator = @"============================================================";
    NSLog(@"\n%@\n%@\n%@", logSeparator, title, content);
}

#pragma mark - NSURLConnection
- (IBAction)NSURLConnectionClicked:(id)sender {
    NSURL *httpsURL = [NSURL URLWithString:[self loadHttpsURL]];
    self.connection = [NSURLConnection connectionWithRequest:[NSURLRequest requestWithURL:httpsURL] delegate:self];
}

//- (void)connection:(NSURLConnection *)connection willSendRequestForAuthenticationChallenge:(NSURLAuthenticationChallenge *)challenge {
//    //1)获取trust object
//    SecTrustRef trust = challenge.protectionSpace.serverTrust;
//    SecTrustResultType result;
//
//    //2)SecTrustEvaluate对trust进行验证
//    OSStatus status = SecTrustEvaluate(trust, &result);
//    if (status == errSecSuccess &&
//        (result == kSecTrustResultProceed ||
//         result == kSecTrustResultUnspecified)) {
//        //3)验证成功，生成NSURLCredential凭证cred，告知challenge的sender使用这个凭证来继续连接
//        NSURLCredential *credential = [NSURLCredential credentialForTrust:trust];
//        [challenge.sender useCredential:credential forAuthenticationChallenge:challenge];
//        NSLog(@"success");
//    } else {
//        //4)验证失败，取消这次验证流程x
//        [challenge.sender cancelAuthenticationChallenge:challenge];
//        NSLog(@"error");
//    }
//}

- (void)connection:(NSURLConnection *)connection willSendRequestForAuthenticationChallenge:(NSURLAuthenticationChallenge *)challenge {
    SecTrustRef serverTrust = challenge.protectionSpace.serverTrust;
    
    NSData *certificateData = [self loadCertificateData];
    NSMutableArray *certificateArray = [NSMutableArray array];
    [certificateArray addObject:(__bridge_transfer id)SecCertificateCreateWithData(NULL, (__bridge CFDataRef)certificateData)];
    SecTrustSetAnchorCertificates(serverTrust, (__bridge CFArrayRef)certificateArray);
    
    // SecTrustEvaluate对trust进行验证
    if (ServerTrustIsValid(serverTrust)) {
        // 验证成功，生成NSURLCredential凭证cred，告知challenge的sender使用这个凭证来继续连接
        NSURLCredential *credential = [NSURLCredential credentialForTrust:serverTrust];
        [challenge.sender useCredential:credential forAuthenticationChallenge:challenge];
        [self printLogWithTitle:@"TrustEvaluate Success" content:@""];
    } else {
        // 验证失败，取消这次验证流程
        [challenge.sender cancelAuthenticationChallenge:challenge];
        [self printLogWithTitle:@"TrustEvaluate Error" content:@""];
    }
}

- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error {
    [self printLogWithTitle:@"NSURLConnection Error:" content:error];
}

- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data {
    NSString *string = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
    [self printLogWithTitle:@"NSURLConnection Data:" content:string];
}

- (void)connectionDidFinishLoading:(NSURLConnection *)connection {
    [self printLogWithTitle:@"NSURLConnection Finish" content:@""];
}

#pragma mark - NSURLSession
- (IBAction)NSURLSessionClicked:(id)sender {
    NSURL *httpsURL = [NSURL URLWithString:[self loadHttpsURL]];
    self.session = [NSURLSession sessionWithConfiguration:[NSURLSessionConfiguration defaultSessionConfiguration] delegate:self delegateQueue:nil];
    NSURLSessionDataTask *task = [self.session dataTaskWithURL:httpsURL];
    [task resume];
}

//- (void)URLSession:(NSURLSession *)session didReceiveChallenge:(NSURLAuthenticationChallenge *)challenge
// completionHandler:(void (^)(NSURLSessionAuthChallengeDisposition disposition, NSURLCredential * _Nullable credential))completionHandler {
//    //1)获取trust object
//    SecTrustRef serverTrust = challenge.protectionSpace.serverTrust;
//    
//    CFArrayRef defaultPolicies = NULL;
//    SecTrustCopyPolicies(serverTrust, &defaultPolicies);
//    CFIndex index = CFArrayGetCount(defaultPolicies);
//    for (CFIndex i = 0; i < index; i++) {
//        NSLog(@"Default Trust Policies: %@", (__bridge id)CFArrayGetValueAtIndex(defaultPolicies, i));
//    }
//    
//    SecTrustResultType result;
//    
//    //2)SecTrustEvaluate对trust进行验证
//    OSStatus status = SecTrustEvaluate(serverTrust, &result);
//    if (status == errSecSuccess &&
//        (result == kSecTrustResultProceed || result == kSecTrustResultUnspecified)) {
//        //3)验证成功，生成NSURLCredential凭证cred，告知challenge的sender使用这个凭证来继续连接
//        NSURLCredential *credential = [NSURLCredential credentialForTrust:serverTrust];
//        [challenge.sender useCredential:credential forAuthenticationChallenge:challenge];
//        
//        completionHandler(NSURLSessionAuthChallengeUseCredential, credential);
//        NSLog(@"success");
//    } else {
//        //4)验证失败，取消这次验证流程
//        completionHandler(NSURLSessionAuthChallengePerformDefaultHandling, nil);
//        NSLog(@"error");
//    }
//}

- (void)URLSession:(NSURLSession *)session didReceiveChallenge:(NSURLAuthenticationChallenge *)challenge
 completionHandler:(void (^)(NSURLSessionAuthChallengeDisposition disposition, NSURLCredential * _Nullable credential))completionHandler {
    SecTrustRef serverTrust = challenge.protectionSpace.serverTrust;
    
    NSData *certificateData = [self loadCertificateData];
    NSMutableArray *certificateArray = [NSMutableArray array];
    [certificateArray addObject:(__bridge_transfer id)SecCertificateCreateWithData(NULL, (__bridge CFDataRef)certificateData)];
    SecTrustSetAnchorCertificates(serverTrust, (__bridge CFArrayRef)certificateArray);
    
    NSURLSessionAuthChallengeDisposition disposition = NSURLSessionAuthChallengePerformDefaultHandling;
    NSURLCredential *credential = nil;
    if (ServerTrustIsValid(serverTrust)) {
        credential = [NSURLCredential credentialForTrust:serverTrust];
        if (credential) {
            disposition = NSURLSessionAuthChallengeUseCredential;
        } else {
            disposition = NSURLSessionAuthChallengePerformDefaultHandling;
        }
        [self printLogWithTitle:@"TrustEvaluate Success" content:@""];
    } else {
        disposition = NSURLSessionAuthChallengeCancelAuthenticationChallenge;
        [self printLogWithTitle:@"TrustEvaluate Error" content:@""];
    }
    completionHandler(disposition, credential);
}

- (void)URLSession:(NSURLSession *)session task:(NSURLSessionTask *)task didReceiveChallenge:(NSURLAuthenticationChallenge *)challenge completionHandler:(void (^)(NSURLSessionAuthChallengeDisposition disposition, NSURLCredential * _Nullable credential))completionHandler {
    
}

- (void)URLSession:(NSURLSession *)session dataTask:(NSURLSessionDataTask *)dataTask didReceiveData:(NSData *)data {
    NSString *string = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
    [self printLogWithTitle:@"NSURLSession Data:" content:string];
}

- (void)URLSession:(NSURLSession *)session task:(NSURLSessionTask *)task didCompleteWithError:(nullable NSError *)error {
    if (error) {
        [self printLogWithTitle:@"NSURLSession Error:" content:error];
    } else {
        [self printLogWithTitle:@"NSURLSession Finish" content:@""];
    }
}

#pragma mark - AFNetworking
- (IBAction)AFNetworkingClicked:(id)sender {
    AFHTTPSessionManager *manager1 = [AFHTTPSessionManager manager];
    manager1.responseSerializer = [AFHTTPResponseSerializer serializer];
    manager1.securityPolicy = [self certificateSecurityPolicy];
    [manager1 GET:[self loadHttpsURL] parameters:nil success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
        NSString *string = [[NSString alloc] initWithData:responseObject encoding:NSUTF8StringEncoding];
        [self printLogWithTitle:@"AFNetworking Data:" content:string];
        [self printLogWithTitle:@"AFNetworking Finish" content:@""];
    } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
        [self printLogWithTitle:@"TrustEvaluate Error" content:error];
    }];
    
    AFHTTPRequestOperationManager *manager2 = [AFHTTPRequestOperationManager manager];
    manager2.responseSerializer = [AFHTTPResponseSerializer serializer];
    manager2.securityPolicy = [self certificateSecurityPolicy];
    [manager2 GET:[self loadHttpsURL] parameters:nil success:^(AFHTTPRequestOperation * _Nonnull operation, id  _Nonnull responseObject) {
        NSString *string = [[NSString alloc] initWithData:responseObject encoding:NSUTF8StringEncoding];
        [self printLogWithTitle:@"AFNetworking Data:" content:string];
        [self printLogWithTitle:@"AFNetworking Finish" content:@""];
    } failure:^(AFHTTPRequestOperation * _Nullable operation, NSError * _Nonnull error) {
        [self printLogWithTitle:@"TrustEvaluate Error" content:error];
    }];
}

- (AFSecurityPolicy *)certificateSecurityPolicy {
    AFSecurityPolicy *securityPolicy = [AFSecurityPolicy policyWithPinningMode:AFSSLPinningModeCertificate];
    securityPolicy.pinnedCertificates = @[[self loadCertificateData]];
    securityPolicy.allowInvalidCertificates = YES;
    return securityPolicy;
}

// 校验证书
- (void)checkCredential:(AFURLSessionManager *)manager {
    [manager setSessionDidBecomeInvalidBlock:^(NSURLSession * _Nonnull session, NSError * _Nonnull error) {
    }];
    
    __weak typeof(manager)weakManager = manager;
    [manager setSessionDidReceiveAuthenticationChallengeBlock:^NSURLSessionAuthChallengeDisposition(NSURLSession*session, NSURLAuthenticationChallenge *challenge, NSURLCredential *__autoreleasing*_credential) {
        NSURLSessionAuthChallengeDisposition disposition = NSURLSessionAuthChallengePerformDefaultHandling;
        __autoreleasing NSURLCredential *credential =nil;
        NSLog(@"authenticationMethod=%@",challenge.protectionSpace.authenticationMethod);
        //判断是核验客户端证书还是服务器证书
        if([challenge.protectionSpace.authenticationMethod isEqualToString:NSURLAuthenticationMethodServerTrust]) {
            // 基于客户端的安全策略来决定是否信任该服务器，不信任的话，也就没必要响应挑战
            if([weakManager.securityPolicy evaluateServerTrust:challenge.protectionSpace.serverTrust forDomain:challenge.protectionSpace.host]) {
                // 创建挑战证书（注：挑战方式为UseCredential和PerformDefaultHandling都需要新建挑战证书）
                NSLog(@"serverTrust=%@",challenge.protectionSpace.serverTrust);
                credential = [NSURLCredential credentialForTrust:challenge.protectionSpace.serverTrust];
                // 确定挑战的方式
                if (credential) {
                    //证书挑战  设计policy,none，则跑到这里
                    disposition = NSURLSessionAuthChallengeUseCredential;
                } else {
                    disposition = NSURLSessionAuthChallengePerformDefaultHandling;
                }
            } else {
                disposition = NSURLSessionAuthChallengeCancelAuthenticationChallenge;
            }
        }
        *_credential = credential;
        return disposition;
    }];
}

#pragma mark - Private Methods
- (NSString *)loadHttpsURL {
    NSString *httpsURL = nil;
    if (self.urlSegmented.selectedSegmentIndex == 0) {
        httpsURL = @"https://www.baidu.com/";
    } else if (self.urlSegmented.selectedSegmentIndex == 1) {
        httpsURL = @"https://www.google.com";
    } else if (self.urlSegmented.selectedSegmentIndex == 2) {
        httpsURL = @"https://kyfw.12306.cn/otn/";
    }
    return httpsURL;
}

- (NSData *)loadCertificateData {
    // 百度根证书：GlobalSign Root CA
    // Google根证书：GeoTrust Global CA
    // 12306根证书：SRCA
    
    NSString *cerName = nil;
    if (self.credSegmented.selectedSegmentIndex == 0) {
        cerName = @"GlobalSign Root CA";
    } else if (self.credSegmented.selectedSegmentIndex == 1) {
        cerName = @"GeoTrust Global CA";
    } else if (self.credSegmented.selectedSegmentIndex == 2) {
        cerName = @"SRCA";
    }
    NSString *cerPath = [[NSBundle mainBundle] pathForResource:cerName ofType:@"cer"];
    NSData *certData = [NSData dataWithContentsOfFile:cerPath];
    return certData;
}

static BOOL ServerTrustIsValid(SecTrustRef serverTrust) {
    BOOL isValid = NO;
    SecTrustResultType result;
    __Require_noErr_Quiet(SecTrustEvaluate(serverTrust, &result), _out);
    
    isValid = (result == kSecTrustResultUnspecified || result == kSecTrustResultProceed);
    
_out:
    return isValid;
}

@end
