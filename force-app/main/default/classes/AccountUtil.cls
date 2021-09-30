public with sharing class AccountUtil {

    public static List<Account> transformarRico(List<Account> listaCuentas)
    {
        for (Account cuenta : listaCuentas) 
        {

            cuenta.Rico__c=true;
        }
        
        LogUtil.debug('Se ha actualizado el valor de cuenta.rico para ' + listaCuentas.size() + ' cuentas');
        return listaCuentas;
    }
    
}
