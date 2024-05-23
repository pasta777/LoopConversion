add_llvm_library( LLVMLoopConversion MODULE
        LoopConversion.cpp
        PLUGIN_TOOL
        opt
)