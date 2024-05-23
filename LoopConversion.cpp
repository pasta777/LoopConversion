#include "llvm/IR/Function.h"
#include "llvm/Pass.h"
#include "llvm/Support/raw_ostream.h"
#include "llvm/Analysis/LoopPass.h"
#include "llvm/Analysis/LoopInfo.h"
#include "llvm/Analysis/LoopUnrollAnalyzer.h"
#include "llvm/Analysis/LoopAnalysisManager.h"

using namespace llvm;

namespace {
    struct LoopConversion : public LoopPass {
        std::vector<BasicBlock*> LoopBasicBlocks;
        std::unordered_map<Value*, Value*> VariablesMap;

        static char ID;
        LoopConversion() : LoopPass(ID) {}

        void mapVariables(Loop *L) {
            Function *F = L->getHeader()->getParent();
            for(BasicBlock &BB : *F) {
                for(Instruction &I : BB) {
                    if(isa<LoadInst>(&I)) {
                        VariablesMap[&I] = I.getOperand(0);
                    }
                }
            }
        }

        bool runOnLoop(Loop *L, LPPassManager &LPM) override {
            mapVariables(L);
            LoopBasicBlocks = L->getBlocksVector();
            errs() << "IN LOOP " << L->getName() << "\n";
            return true;
        }
    };
}

char LoopConversion::ID = 0;
static RegisterPass<LoopConversion> X("loop-conversion", "Loop Conversion");