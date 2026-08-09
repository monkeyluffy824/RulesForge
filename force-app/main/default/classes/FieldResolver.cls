public class FieldResolver {
    public static void collectParentFields(ASTNode node, List<String> fields){
        if(node == null){
            return;
        }
        
        if(node instanceOf FLDNode){
            FLDNode fldNode = (FLDNode) node;
            if(fldNode.traversal != null){
                fields.add(fldNode.fieldPath);
            }
        }
        
        if(node instanceOf LITNode){
            return;
        }
        
        if(node instanceOf CmpNode){
            CmpNode cmpNode = (CmpNode) node;
            collectParentFields(cmpNode.left,fields);
            collectParentFields(cmpNode.right,fields);
            return;
        }
        
        if(node instanceOf FunNode){
            FunNode funNode = (FunNode) node;
            if(funNode.args != null){
                for(ASTNode arg: funNode.args){
                   collectParentFields(arg,fields);
                }
            }
        }
        
        
    }
    
    public static Map<Id,SObject> enrichRecords(String objectName, Set<String> parentFields, Set<Id> recordIds){
        if(parentFields.size() == 0){
            return new Map<Id,SObject>();
        }
        for(String fld: parentFields){
            if(!validateParentField(fld)){
                throw new AuraHandledException('Invalid Field Name Found'); // To be changed later to custom handled exception.
            }
        }
        String query = 'SELECT Id,' + String.join(new List<String>(parentFields), ', ') + ' FROM '+ objectName + ' WHERE Id IN :recIds';
        Map<String, Object> binds = new Map<String, Object>{
                'recIds' => recordIds
            };
        Map<Id,SObject> records = new Map<Id,SObject>((List<SObject>)Database.queryWithBinds(query,binds,AccessLevel.USER_MODE));
               
        return records;
    }
    
    public static Object resolveValue(FLDNode fldNode, SObject newRecord, SObject oldRecord){
        SObject target;
        if(fldNode.ctx == 'old'){
            if(oldRecord == null){
                return null;
            }
            target = oldRecord;
        }else{
            if(newRecord == null){
                return null;
            }
            
            target = newRecord;
        }
        if(fldNode.traversal == null){
            return target.get(fldNode.fieldPath);
        }else if(fldNode.traversal.size() == 2){
            SObject current = (SObject) target.getSObject(fldNode.traversal[0]);
            if(current == null){
                return null;
            }
            return current.get(fldNode.traversal[1]);
        }else{
            throw new AuraHandledException('Incorrect traversal field found');
        }
        
        
    }
    
    private static Boolean validateParentField(String fieldName){
        Pattern p = Pattern.compile('^[A-Za-z0-9_.]+$');
        Matcher m = p.matcher(fieldName);
        return m.matches();
    }
}