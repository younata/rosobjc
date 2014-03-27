#import "ROSNode.h"
#import "ROSCore.h"

using namespace Cedar::Matchers;
using namespace Cedar::Doubles;

SPEC_BEGIN(ROSNodeSpec)

describe(@"ROSNode", ^{
    __block ROSNode *subject;

    describe(@"initialized without core", ^{
        beforeEach(^{
            subject = [[ROSNode alloc] init];
        });
        
        it(@"should have a bunch of nil properties", ^{
            subject.core should be_nil;
            subject.masterURI should be_nil;
            subject.name should equal(@"Untitled");
            subject.delegate should be_nil;
        });
    });
    
    beforeEach(^{
        [[ROSCore sharedCore] setMasterURI:@"http://localhost:11311/"];
        [[ROSCore sharedCore] setInitialized:YES];
        
        subject = [[ROSCore sharedCore] createNode:@"testNode"];
    });
    
    afterEach(^{
        [[ROSCore sharedCore] signalShutdown:@""];
    });
    
    describe(@"Not publishing", ^{
        static NSString *topic = @"/example";
        
        it(@"should not publishesTopic:", ^{
            [subject publishesTopic:topic] should be_falsy;
        });
    });
});

SPEC_END
