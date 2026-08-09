public class ASTDeserializer {
    public Static ASTNode deserializeString(String astJson){
        if(String.isBlank(astJson)){
            throw new AuraHandledException('Cannot deserialize empty AST'); // To be changed later to custom handled exception.
        }
        System.debug(JSON.deserializeUntyped(astJson));
		Map<String,Object> rawJson= (Map<String, Object>) JSON.deserializeUntyped(astJson);
        return buildNode(rawJson);
		        
    }
    
    private static ASTNode buildNode(Map<String,Object> rawJson){
        String typ = (String) rawJson.get('t');
        Switch on typ{
            When 'FUNC'{
                return buildFunNode(rawJson);
            }
            When 'CMP'{
                return buildCmpNode(rawJson);
            }
            When 'FLD'{
                return buildFLDNode(rawJson);
            }
            When 'LIT'{
                return buildLITNode(rawJson);
            }
            when else{
                throw new AuraHandledException('Unknown Type'); // To be changed later to custom handled exception.
            }
        }
        
    }
    
    private static FunNode buildFunNode(Map<String,Object> raw){
        FunNode node = new FunNode();
        node.nodeType = (String) raw.get('t');
        node.returnType = (String) raw.get('returnType');
        node.name = (String) raw.get('n');
        node.args = new List<ASTNode>();
        List<Object> rawArgs = (List<Object>) raw.get('a');
        if(rawArgs != null){
            for(Object arg: rawArgs){
                node.args.add(buildNode((Map<String,Object>) arg));
            }
        }
        
        return node;
    }
    
    private static CmpNode buildCmpNode(Map<String,Object> raw){
     	CmpNode node = new CmpNode();
        node.nodeType = (String) raw.get('t');
        node.returnType = (String) raw.get('returnType');
        node.op = (String) raw.get('op');
        node.left = buildNode((Map<String,Object>) raw.get('l'));
        node.right = buildNode((Map<String,Object>) raw.get('r'));
        
        return node;
    }
    
    private static FLDNode buildFLDNode(Map<String,Object> raw){
        FLDNode node = new FLDNode();
        node.nodeType = (String) raw.get('t');
        node.returnType = (String) raw.get('returnType');
        node.fieldPath = (String) raw.get('v');
        node.ctx = (String) raw.get('ctx');
        node.dt = (String) raw.get('dt');
        if(raw.get('tr') == null){
            node.traversal = null;
        }else{
            List<String> temp = new List<String>();
            for(Object tep: (List<Object>)raw.get('tr')){
                temp.add(tep == null ? null: (String) tep);
            }
            node.traversal = temp;
        }        
        return node;
    }
    
    private static LITNode buildLITNode(Map<String,Object> raw){
        LITNode node = new LITNode();
        node.nodeType = (String) raw.get('t');
        node.returnType = (String) raw.get('returnType');
        node.value =   raw.get('v');
        node.dt = (String) raw.get('dt');
        
        return node;
    }
}