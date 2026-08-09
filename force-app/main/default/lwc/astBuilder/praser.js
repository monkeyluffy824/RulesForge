import { tokenType } from "./tokenizer.js";

export class Praser{
    constructor(tokens,functionRegistory,fieldMetadata,parentFieldFetcher){
        this.tokens = tokens;
        this.functionRegistory = functionRegistory;
        this.fieldMetadata = fieldMetadata;
        this.position =0;
        this.parentFieldFetcher = parentFieldFetcher;
        this.errors =[];
    }

    async parse(){
        if(this.tokens.length === 0){
            throw new PraseError('Empty list of tokens');
        }

        const ast = await this.parseExpression();

        if(this.position<this.tokens.length){
            throw new PraseError(`Unexpected ${this.tokens[this.position].literal} - Expression Ended`);
        }

        return ast;
    }

    consume(){
        return this.tokens[this.position++];
    }

    current(){
        return this.tokens[this.position];
    }

    peek(offset = 1){
        return this.tokens[this.position+offset];
    }

    expect(type,message){
        if(!this.current() || this.current.type !== type){
            throw new PraseError(message || `Expected Type ${type}`);
        }

        return this.consume();
    }

    getPrecedence(token){
        if(token.type !== tokenType.ARTHEMETIC_OP){
            return 0;
        }else if(token.literal === '*' || token.literal === '/'){
            return 2;
        }else if(token.literal === '+' || token.literal === '-'){
            return 1;
        }

        return 0;
    }

    async parseExpression(){
        if(!this.current()){
            throw new PraseError(`unexpected End of expression`);
        }

        if(this.current().type === tokenType.FUNCTION){
            return await this.parseFunctionCall();
        }else{
            return await this.parseComparision();
        }
    }


    buildLitNode(token){
        const node ={ "t":"LIT", "v":token.literal, "dt":token.type, "returnType":token.type};
        return node;
    }

    async buildFieldNode(token){
        const node = {"t":"FLD"};
        let recField = token.literal;
        let field =recField.split('.').slice(1).join('.');
        node["v"] = field;
        if(field.includes('.')){
            node["tr"] = field.split('.');
        }
        if(recField.toLowerCase().startsWith("record.")){
            node["ctx"] = "new";
            
        }else if(recField.toLowerCase().startsWith("oldrecord.")){
            node["ctx"] = "old";
        }
        node["dt"] = node["returnType"] = this.fieldMetadata[field] || await this.parentFieldFetcher(node["tr"]);
        return node;

    }

    async parsePrimary(){
        let currentToken = this.current();
        switch(currentToken.type){
            case tokenType.FUNCTION:
                return await this.parseFunctionCall();
            case tokenType.FIELD:
                this.consume();
                return await this.buildFieldNode(currentToken);
            case tokenType.NUMBER:
                this.consume();
                return this.buildLitNode(currentToken);
            case tokenType.STRING:
                this.consume();
                return this.buildLitNode(currentToken);
            case tokenType.BOOLEAN:
                this.consume();
                return this.buildLitNode(currentToken);
            case tokenType.NULL:
                this.consume();
                return this.buildLitNode(currentToken);
            case tokenType.LPAREN:
                this.consume();
                let tree = await this.parseArthemetic(0);
                if(this.current().type !== tokenType.RPAREN){
                    throw new PraseError(`Expected '${tokenType.RPAREN}'`);
                }
                this.consume();
                return tree;
            case tokenType.ARTHEMETIC_OP:
                if(currentToken.literal === '-'){
                    if(this.peek().type !== tokenType.NUMBER){
                        throw new PraseError ('Expected Number');
                    }
                    this.consume();
                    let value = '-'+ this.current().literal;
                    currentToken.literal = value;
                    currentToken.type = this.current().type;
                    this.consume();
                    return this.buildLitNode(currentToken);
                }else{
                    throw new PraseError(`Unexpected token  ${currentToken.literal}`);
                }
            default:
                throw new PraseError("Expected a Value or Field Reference");

        }
    }


    async parseArthemetic(minBindingPower =0){
        let left = null;
        left = await this.parsePrimary();
        while(true){
            let op = this.current();
            if(op?.type !== tokenType.ARTHEMETIC_OP){
                return left;
            }
            let leftBindingPower = this.getPrecedence(op);

            if(leftBindingPower <= minBindingPower){
                return left;
            }

            this.consume();

            let right = await this.parseArthemetic(leftBindingPower);

            left = this.buildArthemeticFunctionNode(left,right,op);
        }
    }


    async parseComparision(){
        let left = await this.parseArthemetic(0);
        let cmp = this.current();
        if(cmp.type !== tokenType.COMPARISON_OP){
            return left;
        }
        this.consume();
        let right = await this.parseArthemetic(0);

        return this.buildCmpNode(left,right,cmp);

    }



    buildCmpNode(left,right,cmp){
        const node = { t:'CMP', op:cmp.literal, l:left, r:right, returnType:tokenType.BOOLEAN };
        return node;
    }

    buildArthemeticFunctionNode(left,right,operator){
        let name;
        if(operator.literal === '+'){
            name = 'ADD';
        }else if(operator.literal === '-'){
            name = 'SUB';
        }else if(operator.literal === '*'){
            name = 'MUL';
        }else{
            name = 'DIVIDE';
        }
        const node = {"t": tokenType.FUNCTION,
                    "n": name,
                    "a": [left,right],
                    "returnType": tokenType.NUMBER};

        return node;
    }

    

    async parseFunctionCall(){
        let name = this.current().literal;
        const node = { t:tokenType.FUNCTION, n:name };
        let args =[];
        if(this.peek().type !== tokenType.LPAREN){
            throw new PraseError(`Expected '('`);
        }else{
            this.consume();
        }
        this.consume();
        while(true){
            let arg = await this.parseExpression();
            args.push(arg);
            
            if(this.current().type === tokenType.RPAREN){
                break;
            }

            if(this.current().type !== tokenType.COMMA){
                throw new PraseError(`Expected ','`);
            }

            
            this.consume();
        }

        this.consume();

        if(this.functionRegistory[name]['argCount'] !== args.length){
            throw new PraseError(`Expected ${this.functionRegistory[name]['argCount']} args got ${args.length}`);
        }

        node['a'] = args;
        node['returnType'] = this.functionRegistory[name]['returnType'];

        return node;
    }

}

class PraseError extends Error{
    constructor(message){
        super(message);
        this.name = 'Parsing Error';
    }
}

