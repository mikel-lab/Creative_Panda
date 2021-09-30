public with sharing class AccountUtil {
    private static List<Opportunity> listaOpptysAsociadas = new List<Opportunity>();

    public static List<Account> transformarRico(List<Account> listaCuentas)
    {
        for (Account cuenta : listaCuentas) 
        {

            cuenta.Rico__c=true;
        }
        
        LogUtil.debug('Se ha actualizado el valor de cuenta.rico para ' + listaCuentas.size() + ' cuentas');
        return listaCuentas;
    }

    public static void crearOpptyAsociada(List<Account> listaCuentas)
    {
        listaOpptysAsociadas = OpportunityUtil.createNewOppty(listaCuentas);
        LogUtil.debug('Se han creado las siguientes oportunidades asociadas: ' + listaOpptysAsociadas.size());
    }

    public static void insertador()
    {

        insert listaOpptysAsociadas;

    }
    
}

//No podemos llamar al metodo crearOpptyAsociada desde el metodo de inserción porque sino no tendría sentido que el handler lo
//llamase previamente. El Insertador debe recoger lo que los otros métodos dejan preparado.