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
        });
    });
});

SPEC_END
