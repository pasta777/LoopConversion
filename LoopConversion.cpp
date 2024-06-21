#include "llvm/IR/Function.h"
#include "llvm/IR/Instruction.h"
#include "llvm/IR/Instructions.h"
#include "llvm/Pass.h"
#include "llvm/Support/raw_ostream.h"
#include "llvm/Analysis/LoopPass.h"
#include "llvm/Analysis/LoopInfo.h"
#include "llvm/Analysis/LoopUnrollAnalyzer.h"
#include "llvm/Analysis/LoopAnalysisManager.h"
#include "llvm/Transforms/Utils/BasicBlockUtils.h"
#include "llvm/IR/IRBuilder.h"
#include "llvm/IR/InstrTypes.h"

using namespace llvm;

namespace {
    struct LoopConversion : public LoopPass {
        std::vector<BasicBlock*> LoopBasicBlocks;
        std::unordered_map<Value*, Value*> VariablesMap;
        Value* Target;

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
        BasicBlock *findCompareBasicBlock(std::vector<BasicBlock*> LoopBasicBlocks) {
            for(size_t i = 0; i < LoopBasicBlocks.size(); i++) {
                for(Instruction &I : *LoopBasicBlocks[i]) {
                    if(isa<ICmpInst>(&I)) {
                        //errs() << "IM THERE\n";
                        return LoopBasicBlocks[i];
                    }
                }
            }
            return nullptr;
        }
        BasicBlock *findEndBlock(BasicBlock* CompareBasicBlock) {
            for(Instruction &I : *CompareBasicBlock) {
                if(BranchInst* BI = dyn_cast<BranchInst>(&I)) {
                    return BI->getSuccessor(1);
                }
            }
            return nullptr;
        }
        BasicBlock *findLoopBlock(BasicBlock* CompareBasicBlock) {
            for(Instruction &I : *CompareBasicBlock) {
                if(BranchInst* BI = dyn_cast<BranchInst>(&I)) {
                    if(BI->getNumOperands() == 3) {
                        return BI->getSuccessor(0);
                    }
                }
            }
            return nullptr;
        }
        BasicBlock* findIterateBlock(BasicBlock* InLoop) {
            for(Instruction &I : *InLoop) {
                if(BranchInst *BI = dyn_cast<BranchInst>(&I)) {
                    if(BI->getNumOperands() == 1) {
                        return BI->getSuccessor(0);
                    }
                }
            }
            return nullptr;
        }
        bool checkInstructions(BasicBlock* BB) {
            if(BB->size() != 4)
                return false;
            int counter = 0;
            for(Instruction &I : *BB) {
                if(counter == 0)
                    if(!isa<LoadInst>(&I))
                        return false;
                if(counter == 1)
                    if(!(isa<AddOperator>(&I) || isa<SubOperator>(&I)))
                        return false;
                if(counter == 2)
                    if(!isa<StoreInst>(&I))
                        return false;
                if(counter == 3)
                    if(!isa<BranchInst>(&I))
                        return false;
                counter++;
            }
            return true;
        }
        bool checkVariables(BasicBlock* InLoop, BasicBlock* IterateBlock, bool &is_add) {
            bool x_check = false;
            is_add = false;
            for(Instruction &I : *InLoop) {
                //errs() << I << "\n";
                if(AddOperator* AO = dyn_cast<AddOperator>(&I)) {
                    Value* Op1 = AO->getOperand(0);
                    Value* Op2 = AO->getOperand(1);
                    if(ConstantInt* CI = dyn_cast<ConstantInt>(Op1)) {
                        if(!isa<ConstantInt>(Op2)) {
                            if (CI->getSExtValue() == 1) {
                                //errs() << "add op, is_add and x_check\n";
                                is_add = true;
                                x_check = true;
                                break;
                            }
                            if (CI->getSExtValue() == -1) {
                                //errs() << "add op, -1, x_check\n";
                                x_check = true;
                                break;
                            }
                        }
                    } else if(ConstantInt* CI = dyn_cast<ConstantInt>(Op2)) {
                        if(!isa<ConstantInt>(Op1)) {
                            if(CI->getSExtValue() == 1) {
                                //errs() << "add op, is_add, x_check\n";
                                is_add = true;
                                x_check = true;
                                break;
                            }
                            if(CI->getSExtValue() == -1) {
                                //errs() << "add op, -1, x_check\n";
                                x_check = true;
                                break;
                            }
                        }
                    }
                }
                if(SubOperator* SO = dyn_cast<SubOperator>(&I)) {
                    Value* Op1 = SO->getOperand(0);
                    Value* Op2 = SO->getOperand(1);
                    if(ConstantInt* CI = dyn_cast<ConstantInt>(Op2)) {
                        if(!isa<ConstantInt>(Op1)) {
                            if(CI->getSExtValue() == 1) {
                                //errs() << "sub op, x_check\n";
                                x_check = true;
                                break;
                            }
                        }
                    }
                }
            }
            bool i_check = false;
            for(Instruction &I : *IterateBlock) {
                if(AddOperator* AO = dyn_cast<AddOperator>(&I)) {
                    if(is_add) {
                        Value *Op1 = AO->getOperand(0);
                        Value *Op2 = AO->getOperand(1);
                        if (ConstantInt *CI = dyn_cast<ConstantInt>(Op1)) {
                            if (!isa<ConstantInt>(Op2)) {
                                if (CI->getSExtValue() == 1) {
                                    //errs() << "i_check, add op, op1\n";
                                    i_check = true;
                                    break;
                                }
                            }
                        } else if (ConstantInt *CI = dyn_cast<ConstantInt>(Op2)) {
                            if (!isa<ConstantInt>(Op1)) {
                                if (CI->getSExtValue() == 1) {
                                    //errs() << "i_check, add op, op2\n";
                                    i_check = true;
                                    break;
                                }
                            }
                        }
                    } else {
                        Value *Op1 = AO->getOperand(0);
                        Value *Op2 = AO->getOperand(1);
                        if (ConstantInt *CI = dyn_cast<ConstantInt>(Op1)) {
                            if (!isa<ConstantInt>(Op2)) {
                                if (CI->getSExtValue() == -1) {
                                    //errs() << "i_check, -1, op1\n";
                                    i_check = true;
                                    break;
                                }
                            }
                        } else if (ConstantInt *CI = dyn_cast<ConstantInt>(Op2)) {
                            if (!isa<ConstantInt>(Op1)) {
                                if (CI->getSExtValue() == -1) {
                                    //errs() << "i_check, -1, op2\n";
                                    i_check = true;
                                    break;
                                }
                            }
                        }
                    }
                }
                if(SubOperator* SO = dyn_cast<SubOperator>(&I)) {
                    if (!is_add) {
                        Value *Op1 = SO->getOperand(0);
                        Value *Op2 = SO->getOperand(1);
                        if (ConstantInt *CI = dyn_cast<ConstantInt>(Op2)) {
                            if (!isa<ConstantInt>(Op1)) {
                                if (CI->getSExtValue() == 1) {
                                    //errs() << "i_check, sub op\n";
                                    i_check = true;
                                    break;
                                }
                            }
                        }
                    }
                }
            }
            return x_check && i_check;
        }
        bool checkCompareBlock(BasicBlock* CompareBlock, BasicBlock* IterateBlock) {
            Value* iterator = nullptr;
            bool is_add = false;
            for(Instruction &I : *IterateBlock) {
                if(BinaryOperator* BO = dyn_cast<BinaryOperator>(&I)) {
                    Value* temp1 = BO->getOperand(0);
                    Value* temp2 = BO->getOperand(1);

                    if(!isa<ConstantInt>(temp1)) {
                        if(ConstantInt* CI = dyn_cast<ConstantInt>(temp2)) {
                            if(CI->getSExtValue() != -1) {
                                is_add = true;
                            }
                        }
                        iterator = VariablesMap[temp1];
                        //errs() << iterator << "\n";
                    } else if(!isa<ConstantInt>(temp2)) {
                        if(ConstantInt* CI = dyn_cast<ConstantInt>(temp1)) {
                            if(CI->getSExtValue() != -1) {
                                is_add = true;
                            }
                        }
                        iterator = VariablesMap[temp2];
                        //errs() << iterator << "\n";
                    } else {
                        return false;
                    }

                }
            }
            if(iterator == nullptr) {
                errs() << "Found no iterator\n";
                return false;
            }
            for(Instruction &I : *CompareBlock) {
                if(ICmpInst* CMP = dyn_cast<ICmpInst>(&I)) {
                    CmpInst::Predicate p = CMP->getSignedPredicate();
                    if(p == CmpInst::ICMP_SLT || p == CmpInst::ICMP_SLE) {
                        if(is_add) {
                            Value *temp = CMP->getOperand(0);
                            if(!isa<ConstantInt>(temp)) {
                                //errs() << VariablesMap[temp] << "\n";
                                if (VariablesMap[temp] != iterator) {
                                    return false;
                                }
                            }
                        } else {
                            Value *temp = CMP->getOperand(1);
                            if(!isa<ConstantInt>(temp)) {
                                //errs() << VariablesMap[temp] << "\n";
                                if (VariablesMap[temp] != iterator) {
                                    return false;
                                }
                            }
                        }
                    } else if(p == CmpInst::ICMP_SGT || p == CmpInst::ICMP_SGE) {
                        if(!is_add) {
                            Value *temp = CMP->getOperand(0);
                            if(!isa<ConstantInt>(temp)) {
                                //errs() << VariablesMap[temp] << "\n";
                                if (VariablesMap[temp] != iterator) {
                                    return false;
                                }
                            }
                        } else {
                            Value *temp = CMP->getOperand(1);
                            if(!isa<ConstantInt>(temp)) {
                                //errs() << VariablesMap[temp] << "\n";
                                if (VariablesMap[temp] != iterator) {
                                    return false;
                                }
                            }
                        }
                    } else return false;
                }
            }
            return true;
        }

        void setTarget(const BasicBlock* inLoop){
            for (const Instruction &I : *inLoop){
                if (isa<LoadInst>(&I)){
                    if (VariablesMap.find(I.getOperand(0)) == VariablesMap.end()){
                        Target = I.getOperand(0);
                    } else {
                        Target = VariablesMap[I.getOperand(0)];
                    }
                }
            }
        }

        void editCompareBB(BasicBlock* cmpBB, bool isAdd){
            BranchInst* branchInst = nullptr;
            ICmpInst* cmpInst = nullptr;
            BasicBlock* loopOutBB = nullptr;
            bool cmpHasEq = false;

            for (Instruction &I : *cmpBB) {
                if (auto *br = dyn_cast<BranchInst>(&I)) {
                    branchInst = br;
                    loopOutBB = br->getSuccessor(1);
                }
                if (auto *cmp = dyn_cast<ICmpInst>(&I)) {
                    cmpHasEq = cmp->getPredicate() == ICmpInst::ICMP_SGE 
                        || cmp->getPredicate() == ICmpInst::ICMP_SLE;
                    cmpInst = cmp;
                }
            }

            if (!branchInst || !cmpInst || !loopOutBB) {
                errs() << "ay cabroon\n";
                return;
            }
            branchInst->eraseFromParent();

            IRBuilder<> builder(cmpBB);
            builder.SetInsertPoint(cmpBB);
            Value* range = builder.CreateSub(cmpInst->getOperand(1), cmpInst->getOperand(0), "range");
            cmpInst->eraseFromParent();
            if (auto* ai = dyn_cast<AllocaInst>(Target)) {
                Value* loadedTarget = builder.CreateLoad(ai->getAllocatedType(), ai, "loadedTarget");
                Value* newValue = builder.CreateAdd(loadedTarget, range, "newValue");
                
                Value* finalValue = newValue;
                if (cmpHasEq) {
                    finalValue 
                        = isAdd
                        ? builder.CreateAdd(newValue, ConstantInt::get(Type::getInt32Ty(cmpInst->getContext()), 1), "finalValue")
                        : builder.CreateSub(newValue, ConstantInt::get(Type::getInt32Ty(cmpInst->getContext()), 1), "finalValue");
                }
                builder.CreateStore(finalValue, ai);
            } else {
                errs() << "???\n";
            }

            builder.CreateBr(loopOutBB);
        }

        void deleteBBs(std::vector<BasicBlock *> &blocks){
            for (BasicBlock *BB : blocks) {
                
                while (!BB->empty()){
                    Instruction &I = BB->back();
                    I.dropAllReferences();
                    I.eraseFromParent();
                }
                BB->eraseFromParent();
            }
        }

        template<typename... Blocks>
        void deleteBBs(Blocks... bbs) {
            std::vector<BasicBlock*> blocks = {bbs...};
            deleteBBs(blocks);
        }

        bool runOnLoop(Loop *L, LPPassManager &LPM) override {
            mapVariables(L);
            LoopBasicBlocks = L->getBlocksVector();
            
            BasicBlock* CompareBasicBlock = findCompareBasicBlock(LoopBasicBlocks);
            if(!CompareBasicBlock) {
                errs() << "CBB not found\n";
                return false;
            }

            BasicBlock* InLoop = findLoopBlock(CompareBasicBlock);
            if(!InLoop) {
                errs() << "IL not found in runOnLoop function\n";
                return false;
            }

            BasicBlock* IterateBlock = findIterateBlock(InLoop);
            if(!IterateBlock) {
                errs() << "IB not found in runOnLoop function\n";
                return false;
            }

            bool isAdd;
            const bool result = checkInstructions(InLoop) && checkInstructions(IterateBlock)
                    && checkVariables(InLoop, IterateBlock, isAdd) && checkCompareBlock(CompareBasicBlock, IterateBlock);
            
            if (result) {
                    setTarget(InLoop);
                    editCompareBB(CompareBasicBlock, isAdd);
                    deleteBBs(InLoop, IterateBlock);
            }
            return result;
        }
    };
}

char LoopConversion::ID = 0;
static RegisterPass<LoopConversion> X("loop-conversion", "Loop Conversion");