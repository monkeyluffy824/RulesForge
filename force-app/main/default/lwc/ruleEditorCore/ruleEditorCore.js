import { LightningElement, track, wire } from 'lwc';
import { CurrentPageReference } from 'lightning/navigation';
import getExistingRuleName from '@salesforce/apex/RuleEditorController.getExistingRuleName';
import getDirectFieldMetadata from '@salesforce/apex/RuleEditorController.getDirectFieldMetadata';
import getRelationshipMetadata from '@salesforce/apex/RuleEditorController.getRelationshipMetadata';
import getFunctionMetadata from '@salesforce/apex/RuleEditorController.getFunctionMetadata';
import getValidationSchema from '@salesforce/apex/RuleEditorController.getValidationSchema';
import saveRule from '@salesforce/apex/RuleEditorController.saveRule';
import { buildAST } from "c/astBuilder";
import {subscribe,unsubscribe,onError} from 'lightning/empApi';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';

export default class RuleEditorCore extends LightningElement {

    metadataName;
    _ruleName;
    _isDirty = false;
    _objAPIName;
    fieldMetadata;
    functionsMetadata;
    validationSchema;
    isSpinner = false;
    channelName = '/event/Rule_Modify__e';
    subscription = {};
    message;
    @track rule={};

    get isDirty(){
        return !this._isDirty;
    }

    @wire(CurrentPageReference)
    getStateParameters(CurrentPageReference){
        if(CurrentPageReference){
            this._ruleName = CurrentPageReference.state.c__ruleName;
            this.metadataName = this._ruleName ? this._ruleName : 'New Rule';
            
        }
    }

    @wire(getExistingRuleName,{ruleName  : '$_ruleName'})
    getExistingRule({data,error}){
        if(data){
            this.rule = data;
            this._objAPIName = this.rule.Object_API_Name__c;
        }
        if(error){
            console.log(error);
        }
    }

    @wire(getDirectFieldMetadata,{objName : '$_objAPIName', fieldName: null})
    getDirectFieldMetadata({data,error}){
        if(data){
            this.fieldMetadata = data;
        }
        
    }

    @wire(getFunctionMetadata)
    getFunMetadata({data,error}){
        if(data){
            this.functionsMetadata = data;
        }
    }

    @wire(getValidationSchema)
    getValidationSchemaWire({data,error}){
        if(data){
            this.validationSchema = data;
        }

    }

    handleBlur(event){
        const componentId = event.target.dataset.id;
        if(componentId === "ruleLabel"){
            this.rule = { ...this.rule, MasterLabel: event.target.value, DeveloperName: event.target.value?.trim()?.replace(" ","_") };
        }
        if(componentId === "ruleObjectName"){
            this.fieldMetadata = null;
            this.rule = { ...this.rule, Object_API_Name__c: event.target.value };
            this._objAPIName = event.target.value ;
        }
        if(componentId === "ruleIsActive"){
            this.rule = { ...this.rule, Is_Active__c: event.target.checked }
        }
        if(componentId === "ruleOrder"){
            this.rule = { ...this.rule, Execution_Order__c: event.target.value }
        }
        if(componentId === "ruleIsBeforeDelete"){
            this.rule = { ...this.rule, Execute_Before_Delete__c: event.target.checked }
        }
        if(componentId === "ruleIsBeforeInsert"){
            this.rule = { ...this.rule, Execute_Before_Insert__c: event.target.checked }
        }
        if(componentId === "ruleIsBeforeUpdate"){
            this.rule = { ...this.rule, Execute_Before_Update__c: event.target.checked }
        }
        if(componentId === "ruleExpression"){
            this.rule = { ...this.rule, Expression__c: event.target.value }
        }

        if(componentId === "ruleMessage"){
            this.rule = { ...this.rule, Error_Message__c: event.target.value }
        }
        this._isDirty = true;

    }


    async astBuildHelper(){
        if(!this.functionsMetadata || !this.validationSchema || !this.fieldMetadata){
            console.error('Not retrived required metadata');
            return;
        }
        const cxtObj ={beforeDelete:this.rule.Execute_Before_Delete__c,chunkSize : 32768,noOfFields : 5, 'parentFieldFetcher': this.parentFieldFetcher};
        const res = await buildAST(this.rule.Expression__c,this.functionsMetadata,this.validationSchema,this.fieldMetadata,cxtObj);
        if(res.success){
            const ruleRequest = {developerName:this.rule?.DeveloperName, label: this.rule?.MasterLabel, objectApiName: this.rule?.Object_API_Name__c, expression: this.rule?.Expression__c, errorMessage: this.rule?.Error_Message__c, isActive: this.rule?.Is_Active__c, executionOrder: this.rule?.Execution_Order__c, hasParentFields: res?.hasParentFields, executeBeforeInsert: this.rule?.Execute_Before_Insert__c, executeBeforeDelete: this.rule?.Execute_Before_Delete__c, executeBeforeUpdate: this.rule?.Execute_Before_Update__c, chunks: res?.chunks};
            console.log(JSON.stringify(this.rule));
            console.log(JSON.stringify(ruleRequest));
            saveRule({request : ruleRequest}).then((res)=>{
                console.log('res', res);

            }).catch(error=>{
                console.log(error);
            });

            
        }
    }

    async handleClick(){
        this.isSpinner = true;
        await this.astBuildHelper();
    }

    parentFieldFetcher = async (fieldName,obName = this._objAPIName)=>{
        try {
        const result = await getRelationshipMetadata({objName: obName,fldNames: fieldName});

        return result[fieldName[1]];
    } catch (error) {
        console.error(error);
        return 'UNKNOWN';
    }
    };

    connectedCallback(){
        this.handleSubscription();
        this.registorError();
    }

    handleSubscription(){
        const callback = (event)=>{
            console.log('psc', JSON.stringify(event));
            this.message = event.data.payload;
            this.handleMessage();
        }

        subscribe(this.channelName,-1,callback).then((response)=>{
            this.subscription = response;
        });
    }


    disconnectedCallback(){
        if(this.subscription){
            unsubscribe(this.subscription,(response)=>{console.warn('Unsubcribed')});
        }
    }

    registorError(){
        onError((error)=>{
            console.error(error);
        });
    }

    handleMessage(){
        if(!this.message){
            return;
        }
        console.log(this.message);
        if(!this.message?.MetaData_Name__c?.includes(this.metadataName)){
            return;
        }
        const record = this.message;
        if(record.Is_Success__c){
            this.showToast('Success','success','Operation Completed Successfully.')
        }else{
            this.showToast('Error','error','Operation failed.')
        }
        if(this.isSpinner){
            this.isSpinner = false;
            this._isDirty=false;
        }
    }

    showToast(title,variant,message){
        const event = new ShowToastEvent({
            title: title,
            message: message,
            variant: variant
        });

        this.dispatchEvent(event);
    }
}