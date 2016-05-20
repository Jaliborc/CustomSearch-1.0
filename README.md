# CustomSearch-1.0
Framework for building search engines in lua. Handles most of the heavy work for you, such as concept separation,
non ascii character support, logical operators and user criteria selection.

### API Overview
|Name|Description|
|:--|:--|
| :Matches(article, search, filters) | Returns wether the given _article_ matches the _search_ query using the _filters_ structure as the criteria. |
| :Find(search, field1, field2, ...) | Returns wether the _search_ string is present on any of the string _fields_ provided.  |
| :Compare(operator, a, b) | Returns an inequality operation between _a_ and _b_, where _operator_ is the string representation of the operation. |

### Filters Specification
The _filters_ data structure allows you to easly build a search engine of your own.
_filters_ is a set of filter objects. Each filter is akin to an independent criteria of the engine: 
if any filter approves the _article_ for a given _search_ query, the _article_ is approved.

For an object to be a filter, it must implement the following fields:

|Name|Description|
|:--|:--|
| :canSearch(operator, search) | Returns wether the filter can process this query. If not _.match_ will not be called and this filter will not be considered for the query.  |
| :match(article, operator, search) | Returns wether this filter approves the _article_ for a given _search_ query. |
| .tags | Optional. Array of identifiers that can be placed at the beggining of a _search_ query to perform a _Match_ using only this filter. |

### Examples
    local Lib = LibStub('CustomSearch-1.0')
    
    Lib:Find('(João)', 'Roses are red', 'Violets are (jóaô)', 'Wait that was wrong') -- true
    Lib:Find('banana', 'Roses are red', 'Violets are jóaô', 'Wait that was wrong') -- false
    
    Lib:Compare('<', 3, 4) -- true
    Lib:Compare('>', 3, 4) -- false
    Lib:Compare('>=', 5, 5) -- true
    
    local Filters = {
      isBanana = {
        tags = {'b', 'ba'},
        
        canSearch = function(self, operator, search)
          return true
        end,
        
        match = function(self, article, operator, search)
          return Lib:Find(article, 'banana')
        end
      },
      
      searchingApple = {
        tags = {'a', 'app'},
        
        canSearch = function(self, operator, search)
          return not operator
        end,
        
        match = function(self, article, operator, search)
          return Lib:Find(search, 'apple')
        end
      }
    }
    
    Lib:Match('Banana', '', Filters) -- true
    Lib:Match('', 'Apple', Filters) -- true
    Lib:Match('', '> Apple', Filters) -- false
    Lib:Match('Apple', 'Banana', Filters) -- false
    Lib:Match('', 'b:Apple', Filters) -- false
    Lib:Match('', 'a:Apple', Filters) -- true
    
