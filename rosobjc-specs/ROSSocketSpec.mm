#import "ROSSocket.h"

using namespace Cedar::Matchers;
using namespace Cedar::Doubles;

SPEC_BEGIN(ROSSocketSpec)

describe(@"ROSSocket", ^{
    __block ROSSocket *subject;

    beforeEach(^{
        subject = [[ROSSocket alloc] init];
    });
    
    // uh... yeah.
});

SPEC_END
