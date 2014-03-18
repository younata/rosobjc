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
            
            [subject.rosobjects addObject:node];
            
            spy_on(subject);
        });
        
        it(@"getBusStats", PENDING);
        
        it(@"getBusInfo", PENDING);
        
        it(@"getMasterUri", ^{
            
            NSArray *ans = call(@"getMasterUri");
            ans[2] should equal(subject.masterURI);
        });
        
        it(@"shutdown", ^{
            NSArray *ans = [subject respondToRPC:@"shutdown" Params:@[callerID, @"shutdown message"]];
            subject should_have received(@selector(signalShutdown));
            ans[0] should equal(@1);
        });
        
        it(@"getPid", ^{
            
            NSArray *ans = call(@"getPid");
        });
        
        it(@"getSubscriptions", ^{
            
            NSArray *ans = call(@"getSubscriptions");
            ans[2] should equal(@[]);
        });
        
        it(@"getPublications", ^{
            
            NSArray *ans = call(@"getPublications");
            ans[2] should equal(@[]);
        });
        
        it(@"paramUpdate", ^{
            
            NSArray *ans = [subject respondToRPC:@"paramUpdate" Params:@[callerID, @"key", @"value"]];
            // hm.
            ans[0] should equal(@(-1));
            ans[2] should equal(@0);
        });
        
        it(@"publisherUpdate", ^{
            
            NSArray *ans = [subject respondToRPC:@"publisherUpdate" Params:@[callerID, @"/topic", @[@"publisherA", @"publisherB"]]];
        });
        
        it(@"requestTopic", ^{
            
            NSArray *ans = [subject respondToRPC:@"requestTopic" Params:@[callerID, @"/topic", @[]]];
            ans[0] should equal(@1);
        });
        
        it(@"should getPublishedTopics", ^{
            [subject getPublishedTopics:@"/"] should equal(@[]);
        });
    });
});

SPEC_END
