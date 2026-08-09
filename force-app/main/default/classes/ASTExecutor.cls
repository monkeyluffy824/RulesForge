public class ASTExecutor {
	private List<StackItem> nodeStack;
    private List<Object> valueStack;
    private Map<String,FunctionDefinition> functionRegistry;
    
    public ASTExecutor(Map<String,FunctionDefinition> functionRegistry){
        this.functionRegistry = functionRegistry;
        this.nodestack = new List<StackItem>();
        this.valueStack = new List<Object>();
    }
    
    public ValidationResult execute(ASTNode root, SObject newRecord, SObject oldRecord, SObject enrichedRecord){
        nodeStack.clear();
        valueStack.clear();
        
        nodeStack.add(new StackItem(root));
        
        While(!nodeStack.isEmpty()){
            StackItem item = (StackItem) popStack(nodeStack);
            if(item.isMarker){
                processMarker(item);
            }else{
                processNode(item.node,newRecord,oldRecord,enrichedRecord);
            }
        }
        if(valueStack.size() != 1){
            throw new AuraHandledException('Error occured during processing');
        }
        Object finalResult = popStack(valueStack);
        
        if(!(finalResult instanceOf Boolean)){
            throw new AuraHandledException('Final Result is not Boolean');
        }
        
        return new ValidationResult((Boolean)finalResult);
    }
    
    private void processNode(ASTNode node, SObject newRecord, SObject oldRecord, SObject enrichedRecord){
        if(node instanceOf LITNode){
            LITNode lit = (LITNode) node;
            valueStack.add(convertToActualType((String)lit.value,lit.returnType));
            return;
        }
        if(node instanceOf FLDNode){
            FLDNode fld = (FLDNode) node;
            Object value = (fld.traversal != null) ? FieldResolver.resolveValue(fld,enrichedRecord,oldRecord): FieldResolver.resolveValue(fld,newRecord,oldRecord);
            valueStack.add(value);
            return;
        }
        
        if(node instanceOf CmpNode){
            CmpNode cmp = (CmpNode) node;
            StackItem itm = new StackItem();
            itm.cmpOp = cmp.op;
            itm.markerType = 'CMP';
            
            nodeStack.add(itm);
            nodeStack.add(new StackItem(cmp.right));
            nodeStack.add(new StackItem(cmp.left));
            return;
        }
        
        if(node instanceOf FunNode){
            FunNode fun = (FunNode) node;
            StackItem itm = new StackItem();
            itm.markerType = 'FUN';
            itm.funName = fun.name;
            itm.argCount = fun.args.size();
            nodeStack.add(itm);
            for(Integer i=fun.args.size()-1; i>=0;i--){
                nodeStack.add(new StackItem(fun.args[i]));
                
            }

            return;
        }
        
        throw new AuraHandledException('Invalid node type encountered');
    }
    
    private void processMarker(StackItem marker){
        if(marker.markerType == 'CMP'){
            Object right = popStack(valueStack);
            Object left  = popStack(valueStack);
            
            Boolean result = ComparisionEvaluator.evaluate(left,right,marker.cmpOp);
            valueStack.add(result);
            return;
        }
        
        if(marker.markerType == 'FUN'){
			List<Object> args = new List<Object>();  
            for(Integer i=0;i<marker.argCount;i++){
                List<Object> temp = new List<Object>{popStack(valueStack)};
                temp.addAll(args);
                args = temp;
            }
            Object result = invokeFunction(marker.funName, args);
            valueStack.add(result);
            return;
        }
    }
    
    private Object popStack(List<Object> stack){
        Object last = stack.get(stack.size()-1);
        stack.remove(stack.size()-1);
        return last;
    }
    
    private Object invokeFunction(String functionName, List<Object> args){
        FunctionDefinition funDef = functionRegistry.get(functionName);
        if(funDef == null){
             throw new AuraHandledException('Function Definition not found'); // to be replaced with custom Error.
        }
        
        Type t = Type.forName(funDef.className);
        Object instance = t.newInstance();
        
        if(!(instance instanceOf Callable)){
            throw new AuraHandledException('Function Definition is not callable'); // to be replaced with custom Error.
        }
        
        Callable handler = (Callable) instance;
        return handler.call(functionName,new Map<String, Object>{'args' => args});
    }
    
    private Object convertToActualType(String value, String returnType){
        Switch on returnType{
            when 'BOOLEAN'{
                return Boolean.valueOf(value);
            }
            when 'STRING'{
                if(value.startsWith('\'') && value.endsWith('\'')){
                    return value.subString(1, value.length()-1);
                }
                return value;
            }
            when 'NUMBER'{
                return Decimal.valueOf(value);
            }
            when 'NULL'{
                return null;
            }
            when else{
                throw new AuraHandledException('return Type not identified for lit'); // to be replaced with custom Error.
            }
               
        }
    }
    
  
    
    private class StackItem{
        ASTNode node;
        Boolean isMarker;
        String markerType;
        String cmpOp;
        String funName;
        Integer argCount;
        
        StackItem(ASTNode node){
            this.node = node;
            this.isMarker = false;
        }
        
        StackItem(){
            this.node = null;
            this.isMarker = true;
        }
    }
    
}