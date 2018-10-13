//
//  JDGenericValue.cpp
//  JSDebugger
//
//  Created by JunyiXie on 6/10/2018.
//

#include "JDGenericValue.h"
using namespace jd;
APInt &APInt::clearUnusedBits() {
    // Compute how many bits are used in the final word
    unsigned WordBits = ((BitWidth-1) % APINT_BITS_PER_WORD) + 1;
    
    // Mask out the high bits.
    uint64_t mask = WORD_MAX >> (APINT_BITS_PER_WORD - WordBits);
        U.VAL &= mask;
    return *this;
    
}

