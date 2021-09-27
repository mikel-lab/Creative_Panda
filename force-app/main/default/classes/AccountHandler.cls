//Tener en cuenta que este no es el único Trigger a nivel de Oportunidad
public with sharing class AccountHandler implements ITrigger {
    public static boolean  createOutboundBudgetCases = false;
    public void bulkBefore(list<SObject> newList, map<Id,SObject> oldMap)
    {
        Utils.Debug(LoggingLevel.DEBUG,'AccountHandler - bulkBefore');
        ActivarAnular_CasosOutbound_Presupuestos__c	 outboundCaseConfig = ActivarAnular_CasosOutbound_Presupuestos__c.getValues('Activo');
        
        if( outboundCaseConfig != null)
        {
            createOutboundBudgetCases = outboundCaseConfig.Habilitados__c;
        }
        else {
            Utils.Debug(LoggingLevel.DEBUG,'El custom setting está deshabilitado');
        }
    }
    
    public void bulkAfter(list<SObject> newList, map<Id,SObject> oldMap)
    {
    }
    
    public void beforeInsert(list<SObject> newList)
    {

        Utils.Debug(LoggingLevel.DEBUG,'AccountHandler - before insert');
      
        // Asignar casos de presupuestos previos.
        AccountUtil.setRelatedCaseToBudget(newList, createOutboundBudgetCases);        
    }
    
    public void beforeUpdate(list<SObject> newList, map<Id,SObject> oldMap)
    {
        
    }
    
    public void beforeDelete(map<Id,SObject> oldMap)
    {
    }
    
    public void afterInsert(list<SObject> newList)
    {
        Utils.Debug(LoggingLevel.DEBUG,'AccountHandler - after insert');

        if (createOutboundBudgetCases)
        {
            // Generar nuevos casos al presupuesto creado
            AccountUtil.createRelatedCaseToBudget(newList);
        }

        AccountUtil.checkCaseSuccess(newList, null);
    }
     
    public void afterUpdate(list<SObject> newList, map<Id,SObject> oldMap)
    {
       AccountUtil.checkCaseSuccess(newList,(map<Id,Account>) oldMap);
    }
     
    public void afterDelete(map<Id,SObject> oldMap)
    {
    }
    
    public void afterUndelete(list<SObject> newList)
    {
    }

    public void andFinally()
    {
    }
}