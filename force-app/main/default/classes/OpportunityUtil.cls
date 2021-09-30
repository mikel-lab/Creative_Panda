global with sharing class OpportunityUtil 
{
    private static List<Opportunity> listaOpptysAsociadas = new List<Opportunity>();
    
    public static List<Opportunity> createNewOppty(List<Account> cuentas) 
    {
        Opportunity opptyAux;
        for(Account cuenta : cuentas)
        {
            opptyAux = new Opportunity();
            opptyAux.Name = cuenta.Name;
            opptyAux.OwnerId = cuenta.Id;
            listaOpptysAsociadas.add(opptyAux);
        }

        return listaOpptysAsociadas;
    }

}
