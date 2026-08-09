public class BuiltinArthemeticFunctions implements Callable{
	public Object call(String action, Map<String,Object> args){
        List<Object> ar = (List<Object>) args.get('args');
        switch on action{
            when 'ADD'{
                return evaluateADD(ar);
            }
            when 'SUB'{
                return evaluateSUB(ar);
            }
            when 'MUL'{
                return evaluateMUL(ar);
            }
            when 'DIVIDE'{
                return evaluateDIV(ar);
            }
            when else{
                throw new AuraHandledException('Unknown function'+action);
            }
        }
    }
    
    private Decimal evaluateADD(List<Object> args){
        isNonNull(args[0],'ADD',1);
        isNonNull(args[1],'ADD',2);
        return (Decimal) args[0] + (Decimal) args[1];
    }
    private Decimal evaluateSUB(List<Object> args){
        isNonNull(args[0],'SUB',1);
        isNonNull(args[1],'SUB',2);
        return (Decimal) args[0] - (Decimal) args[1];
    }
    private Decimal evaluateMUL(List<Object> args){
        isNonNull(args[0],'MUL',1);
        isNonNull(args[1],'MUL',2);
        return (Decimal) args[0] * (Decimal) args[1];
    }
    private Decimal evaluateDIV(List<Object> args){
        isNonNull(args[0],'DIVIDE',1);
        isNonNull(args[1],'DIVIDE',2);
        if((Decimal) args[1] == 0){
            throw new AuraHandledException('Divide by Zero Error');
        }
        return (Decimal) args[0] / (Decimal) args[1];
    }
    private void isNonNull(Object value, String function, Integer pos){
        if(value == null){
            throw new AuraHandledException(function+ 'received null argument at pos:' + pos);
        }
    }
}