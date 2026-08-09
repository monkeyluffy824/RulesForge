public class ComparisionEvaluator {
    public static Boolean evaluate(Object left, Object right, String op){
        
        
        switch on op{
            when '=='{
                return evaluateEquals(left,right);
            }
            when '!='{
                return !evaluateEquals(left,right);
            }
            when '>','<','>=','<='{
                if(nullCheckForComp(left,right)){
                    return false;
                }
                return checkInstanceAndCmp(left,right,op);
            }
            when else{
                throw new AuraHandledException('Invalid Instances For Comparision');
            }
            
        }
    }
    
    
    private static Boolean evaluateEquals(Object left, Object right){
        if(left == null && right == null){
           return true;
        }else if(left == null || right == null){
           return false;
        }else{
            return left.equals(right);
        }
   }
    
    private static Boolean nullCheckForComp(Object left, Object right){
        if(left == null || right == null){
            return true;
        }
        return false;
    }
    
    private static Boolean compareDecimal(Decimal left, Decimal right, String op){
        switch on op{
            when '>'{
                return left > right;
            }
            when '<'{
                return left < right;
            }
            when '>='{
                return left >= right;
            }
            when '<='{
                return left <= right;
            }
            when else{
                throw new AuraHandledException('Invalid Evaluator for Decimals'); // To be changed later to custom handled exception.
            }
        }
        
    }
    
    private static Boolean compareString(String left, String right, String op){
         switch on op{
            when '=='{
                return left == right;
            }
            when '!='{
                return left != right;
            }
            when else{
                throw new AuraHandledException('Invalid Evaluator for String'); // To be changed later to custom handled exception.
            }
         }
    }
    
    private static Boolean compareDate(Date left, Date right, String op){
        switch on op{
            when '>'{
                return left > right;
            }
            when '<'{
                return left < right;
            }
            when '>='{
                return left >= right;
            }
            when '<='{
                return left <= right;
            }
            when else{
                throw new AuraHandledException('Invalid Evaluator for Date'); // To be changed later to custom handled exception.
            }
        }
    }
    
    private static Boolean compareDateTime(Datetime left, Datetime right, String op){
        switch on op{
            when '>'{
                return left > right;
            }
            when '<'{
                return left < right;
            }
            when '>='{
                return left >= right;
            }
            when '<='{
                return left <= right;
            }
            when else{
                throw new AuraHandledException('Invalid Evaluator for Date Time'); // To be changed later to custom handled exception.
            }
        }
    }
    
    private static Boolean checkInstanceAndCmp(Object left, Object right, String op){
        if(left instanceOf Decimal && right instanceOf Decimal){
            return compareDecimal((Decimal) left, (Decimal) right, op);
        }else if(left instanceOf String && right instanceOf String){
            return compareString((String) left, (String) right, op);
        }else if(left instanceOf Date && right instanceOf Date){
            return compareDate((Date) left, (Date) right, op);
        }else if(left instanceOf Datetime && right instanceOf Datetime){
            return compareDate((Date) left, (Date) right, op);
        }else{
            throw new AuraHandledException('Invalid Instances For Comparision'); // To be changed later to custom handled exception.
        }
    }
    
    
}