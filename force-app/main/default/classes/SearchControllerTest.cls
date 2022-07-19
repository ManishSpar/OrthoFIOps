@isTest
public class SearchControllerTest {
	@isTest
    static void testSearch() {
        Account acObj = new Account(Name='Sam', Phone='1234565788');
        insert acObj;
        List<SearchController.FilterDataWrapper> lstSearchResults = SearchController.search('Sam', 'Account', null);
        System.assert(lstSearchResults != null);
        
        List<SearchController.FilterDataWrapper> lstSearchResults2 = SearchController.search('Sam', 'Account', 'Phone=\'1234565788\'');
        System.assert(lstSearchResults2 != null);
        
        List<SearchController.FilterDataWrapper> lstSearchResults3 = SearchController.search(null, 'Account', null);
        System.assert(lstSearchResults3 != null);
    }
}