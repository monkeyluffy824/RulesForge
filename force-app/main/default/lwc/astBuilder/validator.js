import {tokenType } from "./tokenizer.js";

class ErrorMessage{
    constructor(message,nodeType){
        this.message = message;
        this.type = nodeType;
    }
}

export class Validator{
    constructor(ast, funSchema){
        this.ast = ast;
        this.funSchema = funSchema;
        this.errors =[];
    }

    walkNode(node,cxtObj){
        if(!node || typeof node !== 'object'){
            return;
        }

        switch(node.t){
            case tokenType.FUNCTION:
                this.validateFun(node);
                node?.a?.forEach(ele => {
                    this.walkNode(ele,cxtObj);
                });
                break;
            case 'CMP':
                this.validateCmp(node);
                this.walkNode(node?.l,cxtObj);
                this.walkNode(node?.r,cxtObj);
                break;
            case 'FLD':
                this.validateFld(node,cxtObj);
                break;
            case 'LIT':
                break;
        }

        return;
    }

    validateFld(node,cxtObj){
        if(node?.dt === 'UNKNOWN'){
            this.errors.push(new ErrorMessage(`Field ${node?.v} is not recognized on this object`,node?.dt));
        }else if(node?.ctx === 'old' && node.tr){
            this.errors.push(new ErrorMessage(`oldrecord doesnot support relationship traversal. Use oldrecord for direct fields only.`,node?.dt));
        }else if(node?.tr  && node?.tr?.length >2){
            this.errors.push(new ErrorMessage(`Field path ${node?.v} exceeds maximum relationship depth of more than 1.`,node?.dt));
        }else if(cxtObj.beforeDelete && node?.ctx === 'new'){
            this.errors.push(new ErrorMessage(`This rule references record. fields but is configured for before delete. Only oldrecord. fields are avaialble during delete.`,node?.dt));
        }
    }

    validateCmp(node){
        if(!node?.op){
            this.errors.push(new ErrorMessage(`Comparator not found.`, node?.returnType));
        }else if(node?.op === '==' || node?.op === '!='){
            if((node?.l?.returnType !== node?.r?.returnType) && (node?.l?.returnType !== 'NULL' && node?.r?.returnType !==tokenType.NULL)){
                this.errors.push( new ErrorMessage(`Both sides of ${node?.op} must be of the same type.`, node?.returnType));
            }
        }else if(node?.op === '>' || node?.op === '<' || node?.op === '>=' || node?.op === '<='){
            const types = [tokenType.BOOLEAN,tokenType.STRING,tokenType.NULL];
            if(types.includes(node?.l?.returnType) || types.includes(node?.r?.returnType)){
                this.errors.push(new ErrorMessage(`Ordering Operators are not valid for ${types.toString()}`,node?.returnType));
            }
        }
    }

    validateFun(node){
        if(!node?.returnType || node?.returnType === 'UNKNOWN'){
            this.errors.push(new ErrorMessage(`Unknown Function ${node?.n}, Register the Function before using it in a rule.`, node?.returnType));
        }
        const name = node.n?.toUpperCase();
        const rule = this.funSchema[name];
        if(!rule){
            this.errors.push(new ErrorMessage(`FUNCTION ${node.n} Not detected`,node?.returnType));
            return;
        }

        for(let i=0;i<rule.args.length;i++){
            const ruleArg = rule.args[i];
            const nodeArg = node.a[i];
            if(!ruleArg?.acceptedTypes?.includes(nodeArg?.returnType)){
                this.errors.push(new ErrorMessage(`Argument Mismatch Expected any one of these ${ruleArg?.acceptedTypes} got ${nodeArg?.returnType}`,node?.returnType));
            }

            if(ruleArg.checkLiteralZero){
                if(nodeArg.t === "LIT" && nodeArg.v === "0"){
                    this.errors.push(new ErrorMessage(`Literal 0 is invalid for this Argument`,node?.returnType));
                }
            }

            if(ruleArg.restrictedValues){
                if(nodeArg.t === "LIT" && ! ruleArg.restrictedValues?.includes(nodeArg.v?.toUpperCase())){
                    this.errors.push(new ErrorMessage(`For this argument The given value ${nodeArg.v} cannot be applied`, node?.returnType));
                }
            }
        }
    }

    validate(cxtObj={}){
        this.errors =[];

        this.walkNode(this.ast,cxtObj);
        if(this.ast && this.ast?.returnType !== tokenType.BOOLEAN){
            this.errors.push(new ErrorMessage(`The root expression must be a boolean.`, this.ast?.returnType));
        }


        return {
            valid: this.errors.length === 0,
            errors:this.errors
        }
    }
}