//
//  JDGenericValue.hpp
//  JSDebugger
//
//  Created by JunyiXie on 6/10/2018.
//

#ifndef JDGenericValue_h
#define JDGenericValue_h

#include <stdio.h>
#include <vector>
namespace jd {
    /// APInt
    /// simple copy from LLVMSupport
    class APInt {
    public:
        typedef uint64_t WordType;
        
        /// This enum is used to hold the constants we needed for APInt.
        enum : unsigned {
            /// Byte size of a word.
            APINT_WORD_SIZE = sizeof(WordType),
            /// Bits in a word.
            APINT_BITS_PER_WORD = APINT_WORD_SIZE * CHAR_BIT
        };
        
        static const WordType WORD_MAX = ~WordType(0);
        
        APInt(unsigned numBits, uint64_t val, bool isSigned = false)
        : BitWidth(numBits) {
            U.VAL = val;
            clearUnusedBits();
        }
        
    private:
        /// This union is used to store the integer value. When the
        /// integer bit-width <= 64, it uses VAL, otherwise it uses pVal.
        union {
            uint64_t VAL;   ///< Used to store the <= 64 bits integer value.
            uint64_t *pVal; ///< Used to store the >64 bits integer value.
        } U;
        
        unsigned BitWidth; ///< The number of bits in this APInt.
        APInt &clearUnusedBits();
    };
    
    /// GenericValue
    using PointerTy = void *;
    
    struct GenericValue {
        struct IntPair {
            unsigned int first;
            unsigned int second;
        };
        union {
            double DoubleVal;
            float FloatVal;
            PointerTy PointerVal;
            struct IntPair UIntPairVal;
            unsigned char Untyped[8];
        };
        APInt IntVal; // also used for long doubles.
        // For aggregate data types.
        std::vector<GenericValue> AggregateVal;
        
        bool byvalParameter = false;
        // to make code faster, set GenericValue to zero could be omitted, but it is
        // potentially can cause problems, since GenericValue to store garbage
        // instead of zero.
        GenericValue() : IntVal(1, 0) {
            UIntPairVal.first = 0;
            UIntPairVal.second = 0;
        }
        explicit GenericValue(void *V) : PointerVal(V), IntVal(1, 0) {}
    };
    
    inline GenericValue PTOGV(void *P) { return GenericValue(P); }
    inline void *GVTOP(const GenericValue &GV) { return GV.PointerVal; }
    
} // end namespace llvm


#endif /* JDGenericValue_h */
