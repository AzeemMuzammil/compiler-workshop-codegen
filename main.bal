import codegen.ir;
import codegen.llvm as ll;
import ballerina/io;

public function main(string irFilePath, string outputLlFilePath) returns error? {
    json irFileContent = check io:fileReadJson(irFilePath);
    ir:Function[] funcs = check (irFileContent).cloneWithType();
    check codeGen(funcs).printModuleToFile(outputLlFilePath);
}

public function codeGen(ir:Function[] funcs) returns ll:Module {
    ll:Context llContext = new;
    ll:Builder llBuilder = llContext.createBuilder();
    ll:Module llModule = llContext.createModule();

    // Function Definitions
    map<ll:FunctionDefn> funcDefns = {};
    foreach ir:Function func in funcs {
        ll:Type[] paramTypes = [];
        foreach int _ in 0..<func.params.length() {
            ll:Type i64Type = "i64";
            paramTypes.push(i64Type);
        }
        ll:FunctionDefn funcDefn =
            llModule.addFunctionDefn(func.name, { returnType: "i64", paramTypes: paramTypes.cloneReadOnly()});
        funcDefns[func.name] = funcDefn;

        // Function Blocks
        map<ir:Block> insnBlocks = {};
        map<ll:BasicBlock> basicBlocks = {};
        foreach [string, ir:Block] block in func.blocks.entries() {
            insnBlocks[block[0]] = block[1];
            basicBlocks[block[0]] = funcDefn.appendBasicBlock(block[0] == "entry" ? () : block[0]);
        }
        llBuilder.positionAtEnd(basicBlocks.get("entry"));

        // Function Parameters
        map<ll:Value> funcParams = {};
        foreach [int, ir:Identifier] param in func.params.enumerate() {
            funcParams[param[1]] = funcDefn.getParam(param[0]);
        }

        // -> param allocations
        map<ll:PointerValue> memAllocs = {};
        foreach [string, ll:Value] param in funcParams.entries() {
            ll:PointerValue allocPtr = llBuilder.alloca("i64");
            llBuilder.store(param[1], allocPtr);
            memAllocs[param[0]] = allocPtr;
        }

        // Function Vars
        // -> Function var allocations
        foreach ir:Identifier 'var in func.vars {
            ll:PointerValue allocPtr = llBuilder.alloca("i64");
            memAllocs['var] = allocPtr;
        }

        // Entry Block
        ir:Label[] generatedBlocks = [];
        generateForInsns(llBuilder, insnBlocks.get("entry").insns, funcDefns, basicBlocks, insnBlocks, memAllocs, generatedBlocks);
    }
    return llModule;
}

function generateForInsns(ll:Builder llBuilder, ir:Insn[] insns, map<ll:FunctionDefn> funcDefns,
        map<ll:BasicBlock> basicBlocks, map<ir:Block> insnBlocks, map<ll:PointerValue> memAllocs,
        ir:Label[] generatedBlocks) {
    foreach ir:Insn insn in insns {
        if insn is ir:Return {
            ir:Operand retOp = insn.op[0];
            if (retOp is ir:Variable) {
                ll:PointerValue resPtr = memAllocs.get(retOp);
                ll:Value retVal = llBuilder.load(resPtr);
                llBuilder.ret(retVal);
            }
        } else if insn is ir:Add {
            ir:Operand lhsOp = insn.op[0];
            ir:Operand rhsOp = insn.op[1];
            ll:Value lhsVal;
            ll:Value rhsVal;
            lhsVal = getArithmeticOpVal(llBuilder, memAllocs, lhsOp);
            rhsVal = getArithmeticOpVal(llBuilder, memAllocs, rhsOp);
            ll:Value arrRes = llBuilder.iArithmeticWrap("add", lhsVal, rhsVal);
            ll:PointerValue resPtr = memAllocs.get(insn.result);
            llBuilder.store(arrRes, resPtr);
        } else if insn is ir:LessThan {
            ir:Operand lhsOp = insn.op[0];
            ir:Operand rhsOp = insn.op[1];
            ll:Value lhsVal;
            ll:Value rhsVal;
            lhsVal = getArithmeticOpVal(llBuilder, memAllocs, lhsOp);
            rhsVal = getArithmeticOpVal(llBuilder, memAllocs, rhsOp);
            ll:Value cmpRes = llBuilder.iCmp("slt", lhsVal, rhsVal);
            ll:Value extRes = llBuilder.zExt(cmpRes, "i64");
            ll:PointerValue resPtr = memAllocs.get(insn.result);
            llBuilder.store(extRes, resPtr);
        } else if insn is ir:JumpIf {
            ir:Operand cdnOp = insn.op[0];
            ll:Value cdnVal;
            cdnVal = getArithmeticOpVal(llBuilder, memAllocs, cdnOp);
            ll:Value cdnTruncVal = llBuilder.trunc(cdnVal, "i1");
            ir:Label ifTrue = insn.ifTrue;
            ir:Label ifFalse = insn.ifFalse;
            llBuilder.condBr(cdnTruncVal, basicBlocks.get(ifTrue), basicBlocks.get(ifFalse));
            llBuilder.positionAtEnd(basicBlocks.get(ifTrue));
            if !generatedBlocks.some(block => ifTrue == block) {
                generateForInsns(llBuilder, insnBlocks.get(ifTrue).insns, funcDefns, basicBlocks, insnBlocks, memAllocs, generatedBlocks);
                generatedBlocks.push(ifTrue);
            }
            llBuilder.positionAtEnd(basicBlocks.get(ifFalse));
            if !generatedBlocks.some(block => ifFalse == block) {
                generateForInsns(llBuilder, insnBlocks.get(ifFalse).insns, funcDefns, basicBlocks, insnBlocks, memAllocs, generatedBlocks);
                generatedBlocks.push(ifFalse);
            }
        } else if insn is ir:Subtract {
            ir:Operand lhsOp = insn.op[0];
            ir:Operand rhsOp = insn.op[1];
            ll:Value lhsVal;
            ll:Value rhsVal;
            lhsVal = getArithmeticOpVal(llBuilder, memAllocs, lhsOp);
            rhsVal = getArithmeticOpVal(llBuilder, memAllocs, rhsOp);
            ll:Value arrRes = llBuilder.iArithmeticWrap("sub", lhsVal, rhsVal);
            ll:PointerValue resPtr = memAllocs.get(insn.result);
            llBuilder.store(arrRes, resPtr);
        } else if insn is ir:Call {
            ll:Value[] callParams = [];
            foreach ir:Operand op in insn.op {
                ll:Value callParam = getArithmeticOpVal(llBuilder, memAllocs, op);
                callParams.push(callParam);
            }
            ll:PointerValue resPtr = memAllocs.get(insn.result);
            ll:Value? callRes = llBuilder.call(funcDefns.get(insn.name), callParams);
            if callRes is ll:Value {
                llBuilder.store(callRes, resPtr);
            }
        }
    }
}

function getArithmeticOpVal(ll:Builder llBuilder, map<ll:PointerValue> memAllocs, ir:Operand op) returns ll:Value {
    ll:Value opVal;
    if op is int {
        opVal = ll:constInt("i64", op);
    } else {
        ll:PointerValue allocPtr = memAllocs.get(op);
        opVal = llBuilder.load(allocPtr);
    }
    return opVal;
}
