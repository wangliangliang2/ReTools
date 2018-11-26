//
//  AnonymousURLProtocol.m
//  AnonymousURLProtocol
//
//  Created by Anonymous on 11/14/18.
//  Copyright © 2018 Anonymous. All rights reserved.
//



#import "AnonymousURLProtocol.h"

static NSString *AnonymousURLProtocolHandleKey = @"isHacked";

@interface AnonymousURLProtocol ()<NSURLSessionDelegate,NSURLSessionTaskDelegate,NSURLSessionDataDelegate>

@property (nonatomic,strong) NSURLSession *session;

@end

@implementation AnonymousURLProtocol

/*
 审核 每个 url 请求 是否需要被用户处理
 返回值：
        NO 不需要
        YES 需要
 
 */
+ (BOOL)canInitWithRequest:(NSURLRequest *)request {

    // 需要对 「已经处理过」的请求放行 否则会导致死循序
    if ([NSURLProtocol propertyForKey:AnonymousURLProtocolHandleKey inRequest:request]) {
        return NO;
    }
    // 自定义处理逻辑
    //    URL 举例 ： https://www.baidu.com/music/v1/1.mp3
    if ([[[request URL] path] containsString:@"/music/v1"]) {
        return YES;
    }else if([[[request URL] host] isEqualToString:@"www.baidu.com"]){
        return YES;
    }
    
    return NO;
}


/*
 在这里可以修改 request 的信息
 例如：
    1. headers
    2. host
 但是一般没啥特别的话 直接返回即可。
 */
+ (NSURLRequest *)canonicalRequestForRequest:(NSURLRequest *)request {

    return request;
}


/*
 其实只是一个缓存策略修改中心
 没啥事情就直接调用父类的实现沿用下就行
 */
+ (BOOL)requestIsCacheEquivalent:(NSURLRequest *)a toRequest:(NSURLRequest *)b {

    return [super requestIsCacheEquivalent:a toRequest:b];
}


- (void)startLoading {

    /*
     重点
     这里需要标记下请求 避免循序
     */
    NSMutableURLRequest *newRequest = [self.request mutableCopy];
    [NSURLProtocol setProperty:@YES forKey:AnonymousURLProtocolHandleKey inRequest:newRequest];
    NSURLSessionConfiguration *configuration = [NSURLSessionConfiguration defaultSessionConfiguration];
    configuration.protocolClasses = @[[AnonymousURLProtocol class]];
    self.session = [NSURLSession sessionWithConfiguration:configuration delegate:self delegateQueue:nil];
    [[self.session dataTaskWithRequest:newRequest] resume];
    
    
}


- (void)stopLoading
{

    [self.session invalidateAndCancel];
    self.session = nil;
}



/*
 初始化 NSURLProtocol 对象
 */
- (instancetype)initWithRequest:(NSURLRequest *)request cachedResponse:(NSCachedURLResponse *)cachedResponse client:(id<NSURLProtocolClient>)client{

    return [super initWithRequest:request cachedResponse:cachedResponse client:client];
}



-(void)URLSession:(NSURLSession *)session task:(NSURLSessionTask *)task didCompleteWithError:(NSError *)error {
    if (error) {
        [self.client URLProtocol:self didFailWithError:error];
    } else {
        [self.client URLProtocolDidFinishLoading:self];
    }
}



/*
 修改请求返回头部信息
 */
- (void)URLSession:(NSURLSession *)session dataTask:(NSURLSessionDataTask *)dataTask didReceiveResponse:(NSURLResponse *)response completionHandler:(void (^)(NSURLSessionResponseDisposition))completionHandler{

    NSHTTPURLResponse *httpResponse = (NSHTTPURLResponse *)response;

    NSHTTPURLResponse *newResponse = [[NSHTTPURLResponse alloc] initWithURL:httpResponse.URL statusCode:400 HTTPVersion:@"HTTP/1.1" headerFields:httpResponse.allHeaderFields];
    /*
     NSURLCacheStorageNotAllowed 如果不想用这个自己改
     */
    [self.client URLProtocol:self didReceiveResponse:newResponse cacheStoragePolicy:NSURLCacheStorageNotAllowed];
    
    
    completionHandler(NSURLSessionResponseAllow);

}


/*
 修改请求返回内容
 */
-(void)URLSession:(NSURLSession *)session dataTask:(NSURLSessionDataTask *)dataTask didReceiveData:(NSData *)data{
    
    [self.client URLProtocol:self didLoadData:[@"替换返回值" dataUsingEncoding:NSUTF8StringEncoding]];
}


- (void)URLSession:(NSURLSession *)session dataTask:(NSURLSessionDataTask *)dataTask willCacheResponse:(NSCachedURLResponse *)proposedResponse completionHandler:(void (^)(NSCachedURLResponse * _Nullable))completionHandler{

    completionHandler(proposedResponse);
}

/*
 对于 https 的拦截 这里还有个证书校验的关口
 */
- (void)URLSession:(NSURLSession *)session didReceiveChallenge:(NSURLAuthenticationChallenge *)challenge completionHandler:(void (^)(NSURLSessionAuthChallengeDisposition, NSURLCredential * _Nullable))completionHandler{
    if ([challenge.protectionSpace.authenticationMethod isEqualToString:NSURLAuthenticationMethodServerTrust]) {
        NSURLCredential *credential = [[NSURLCredential alloc] initWithTrust:challenge.protectionSpace.serverTrust];

        [challenge.sender useCredential:credential forAuthenticationChallenge:challenge];
        completionHandler(NSURLSessionAuthChallengeUseCredential,credential);

    }
    else {
        [challenge.sender continueWithoutCredentialForAuthenticationChallenge:challenge];
        completionHandler(NSURLSessionAuthChallengeCancelAuthenticationChallenge,nil);

    }
    
    
}

/*
    1.不能自动运行的动态库是没有梦想的
    2.编译命令：
            clang -framework Foundation -o anonymousURLProtocol.dylib -dynamiclib AnonymousURLProtocol.m
 */

__attribute__ ((constructor)) static void anonymousURLProtocolEntrypoint() {
    if ([NSURLProtocol registerClass:[AnonymousURLProtocol class]]) {
        NSLog(@"插入 AnonymousURLProtocol 成功! ");
    }
}



@end
