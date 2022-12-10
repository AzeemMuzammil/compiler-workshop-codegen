public type Identifier string; // starts with "%"

public type Function record {|
    string name;
    map<Block> blocks;
    Identifier[] params;
    Identifier[] vars;
|};

public type Block record {|
    Insn[] insns;
|};

public type Variable Identifier;
public type Operand Variable|int;
public type Label string;

public type Insn Return|Add|LessThan|JumpIf|Subtract|Call;

public type Return record {|
    "return" kind;
    Operand[1] op;
|};

public type Add record {|
    "add" kind;
    Operand[2] op;
    Variable result;
|};

public type LessThan record {|
    "lessThan" kind;
    Operand[2] op;
    Variable result;
|};

public type JumpIf record {|
    "jumpIf" kind;
    Operand[1] op;
    Label ifTrue;
    Label ifFalse;
|};

public type Subtract record {|
    "subtract" kind;
    Operand[2] op;
    Variable result;
|};

public type Call record {|
    "call" kind;
    string name;
    Operand[] op;
    Variable result;
|};
