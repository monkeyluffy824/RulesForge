import { Praser } from "./praser.js";
import { GetTokens } from "./tokenizer.js";
import { Validator } from "./validator.js";

function checkForParentFields(node){
    if(!node || typeof node !== "object"){
        return false;
    }

    if(node?.t === 'FLD'){
        return node?.tr !== undefined && node?.tr !== null;
    }

    if(node?.t === 'FUN'){
        return node?.a?.some(ele=>checkForParentFields(ele));
    }

    if(node?.t === 'CMP'){
        return checkForParentFields(node?.l) || checkForParentFields(node?.r);
    }

    if(node?.t === 'LIT'){
        return false;
    }
}

function splitToChunks(minifiedAst,chunkSize,noOfFields){
    const MAX_CHUNK_SIZE = noOfFields*chunkSize;
    if(minifiedAst?.length > MAX_CHUNK_SIZE){
        throw new Error(`This Rule Exceeded the Maximum Size.`);
    }
    const chunks =[];
    for(let i=0;i<noOfFields;i++){
        chunks.push(minifiedAst.slice(i*chunkSize, (i+1)*chunkSize));
    }
    return chunks;
}

export async function buildAST(expression,functionRegistory,validationSchema,fieldMetadata,cxtObj={chunkSize : 32768,noOfFields : 5}){
    try{
        const gt = new GetTokens(expression);
        const tokens = gt.tokens;
        const praser = new Praser(tokens,functionRegistory,fieldMetadata,cxtObj.parentFieldFetcher);
        const tree = await praser.parse();
        const validation = new Validator(tree,validationSchema);
        const result = validation.validate(cxtObj);
        if(!result.valid){
            throw new Error(result.errors.map(err => err.message).join('\n'));
        }
        const hasParentFields = checkForParentFields(tree);
        const minifiedAst = JSON.stringify(tree);
        const chunks = splitToChunks(minifiedAst,cxtObj.chunkSize,cxtObj.noOfFields);
        return {'success': true, 'ast': tree, 'minified': minifiedAst, 'chunks': chunks, 'hasParentFields': hasParentFields, 'charCount': minifiedAst.length};
    }catch(e){
        console.error(e.message);
        return {'success': false, "errors": e.message};
    }
    

}