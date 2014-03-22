#import "ROSCore.h"
#import "ROSNode.h"

using namespace Cedar::Matchers;
using namespace Cedar::Doubles;

SPEC_BEGIN(ROSCoreSpec)

describe(@"ROSCore", ^{
    __block ROSCore *subject;

    beforeEach(^{
        subject = [[ROSCore alloc] init];
    });
    
    describe(@"initial state", ^{
        it(@"should start with everything turned off", ^{
            subject.isInitialized should be_falsy;
            subject.isShutdown should be_falsy;
            subject.isShutdownRequested should be_falsy;
        });
        
        it(@"should start the httpserver on initializing", ^{
            [subject setInitialized:YES];
            subject.isInitialized should be_truthy;
            subject.isShutdown should be_falsy;
            subject.isShutdownRequested should be_falsy;
            subject.rpcPort should be_gte(8080);
        });
    });
    
    describe(@"shutting down", ^{
        beforeEach(^{
            [subject setInitialized:YES];
            [subject signalShutdown:@""];
        });
        
        it(@"should shut down things.", ^{
            subject.isShutdown should be_truthy;
            subject.isShutdownRequested should be_truthy;
        });
    });
    
    describe(@"nodes", ^{
        beforeEach(^{
            [subject setInitialized:YES];
        });
        
        it(@"should create nodes", ^{
            ROSNode *node = [subject createNode:@"example"];
            node.name should equal(@"example");
            node.core should equal(subject);
            node.masterURI should equal(subject.masterURI);
        });
    });
    
    // slave API
    describe(@"responding to RPC calls: ", ^{
        static NSString *callerID = @"/examplenode";
        NSArray *(^call)(NSString *) = ^NSArray *(NSString *method){
            NSArray *ret = [subject respondToRPC:method Params:@[callerID]];
            ret[0] should equal(@1);
            return ret;
        };
        
        beforeEach(^{
            [subject setInitialized:YES];
            ROSNode *node = fake_for([ROSNode class]);
            
            node stub_method("getBusStats:").and_return(@[@1, @"", @[]]);
            node stub_method("getBusInfo:").and_return(@[@1, @"", @[]]);
            node stub_method("getMasterUri:").and_return(@[@1, subject.masterURI, subject.masterURI]);
            node stub_method("getSubscriptions:").and_return(@[@1, @"subscriptions", @[]]);
            node stub_method("getPublications:").and_return(@[@1, @"publications", @[]]);
            node stub_method(@selector(paramUpdate:key:val:)).and_return(@[@1, @"", @0]);
            node stub_method(@selector(publisherUpdate:topic:publishers:)).and_return(@[@1, @"", @0]);
            node stub_method(@selector(requestTopic:topic:protocols:)).and_return(@[@1, @"", @0]);
            node stub_method(@selector(getPublishedTopics:)).and_return(@[]);
            
            [subject.rosobjects addObject:node];
            
            spy_on(subject);
        });
        
        it(@"getBusStats", PENDING);
        
        it(@"getBusInfo", PENDING);
        
        it(@"getMasterUri", ^{
            NSArray *ans = call(@"getMasterUri");
            ans[1] should equal(subject.masterURI);
            ans[2] should equal(subject.masterURI);
        });
        
        it(@"shutdown", ^{
            NSArray *ans = [subject respondToRPC:@"shutdown"
                                          Params:@[callerID, @"shutdown message"]];
            subject should have_received(@selector(signalShutdown:));
            ans[0] should equal(@1);
            ans[1] should equal(@"shutdown message");
            ans[2] should equal(@0);
        });
        
        it(@"getPid", ^{
            NSArray *ans = call(@"getPid");
            ans[1] should equal(@"");
        });
        
        it(@"getSubscriptions", ^{
            NSArray *ans = call(@"getSubscriptions");
            ans[1] should equal(@"subscriptions");
            ans[2] should equal(@[]);
        });
        
        it(@"getPublications", ^{
            NSArray *ans = call(@"getPublications");
            ans[1] should equal(@"publications");
            ans[2] should equal(@[]);
        });
        
        it(@"paramUpdate", ^{
            NSArray *ans = [subject respondToRPC:@"paramUpdate" Params:@[callerID, @"key", @"value"]];
            // hm.
            ans[0] should equal(@1);
            ans[1] should equal(@"");
            ans[2] should equal(@0);
        });
        
        it(@"publisherUpdate", ^{
            NSArray *ans = [subject respondToRPC:@"publisherUpdate" Params:@[callerID, @"/topic", @[@"publisherA", @"publisherB"]]];
            ans[0] should equal(@1);
            ans[1] should equal(@"");
            ans[2] should equal(@0);
        });
        
        it(@"requestTopic", ^{
            NSArray *ans = [subject respondToRPC:@"requestTopic" Params:@[callerID, @"/topic", @[]]];
            ans[0] should equal(@1);
            ans[1] should equal(@"");
            ans[2] should equal(@0);
        });
        
        it(@"should getPublishedTopics", ^{
            [subject getPublishedTopics:@"/"] should equal(@[]);
        });
    });
});

SPEC_END
