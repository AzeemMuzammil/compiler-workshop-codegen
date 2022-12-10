import codegen.ir;
import codegen.llvm as ll;
import ballerina/io;

public function main(string irFilePath, string outputLlFilePath) returns error? {
    json irFileContent = check io:fileReadJson(irFilePath);
    ir:Function[] funcs = check (irFileContent).cloneWithType();
    check codeGen(funcs).printModuleToFile(outputLlFilePath);
}

public function codeGen(ir:Function[] funcs) returns ll:Module {
    // Change the following code to use `funcs` variable and generate code
    ll:Context context = new;
    ll:Builder builder = context.createBuilder();
    ll:Module module = context.createModule();
    ll:FunctionDefn foo = module.addFunctionDefn("add", { returnType: "i64", paramTypes: ["i64", "i64"] });
    ll:BasicBlock entryBlock = foo.appendBasicBlock();
    builder.positionAtEnd(entryBlock);
    ll:Value r0 = foo.getParam(0);
    ll:Value r1 = foo.getParam(1);
    ll:PointerValue r3 = builder.alloca("i64");
    builder.store(r0, r3);
    ll:PointerValue r4 = builder.alloca("i64");
    builder.store(r1, r4);
    ll:PointerValue r5 = builder.alloca("i64");
    ll:Value r6 = builder.load(r3);
    ll:Value r7 = builder.load(r4);
    ll:Value r8 = builder.iArithmeticWrap("add", r6, r7);
    builder.store(r8, r5);
    ll:Value r9 = builder.load(r5);
    builder.ret(r9);
    return module;
}
