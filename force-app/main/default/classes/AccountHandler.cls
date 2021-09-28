//Tener en cuenta que este no es el único Trigger a nivel de Oportunidad
public with sharing class AccountHandler implements ITrigger {
    List<Account> listaCuentas = new List<Account>();
   
    public void bulkBefore(list<SObject> newList, map<Id,SObject> oldMap)
    {
        listaCuentas= newList;
    }
    
    public void bulkAfter(list<SObject> newList, map<Id,SObject> oldMap)
    {
        

        
       /* for (type cuenta : newList) 
        {
            listaCuentas.add(cuenta);
            
        }*/
        //Map<Id,Account> mapaCuentas = new Map<Id,Account>([SELECT Name,Id, Rico__c FROM Account ]);
                                                  
    }
    
    
    public void beforeInsert(list<SObject> newList)
    {
        AccountUtil.transformarRico(listaCuentas);
               
    }
    
    public void beforeUpdate(list<SObject> newList, map<Id,SObject> oldMap)
    {
        
    }
    
    public void beforeDelete(map<Id,SObject> oldMap)
    {
    }
    
    public void afterInsert(list<SObject> newList)
    {
        
        
    }
     
    public void afterUpdate(list<SObject> newList, map<Id,SObject> oldMap)
    {
       
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