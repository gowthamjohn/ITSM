/**
 * Created 04.05.2020.
 */

public with sharing class SettingPageHelper {

    public static String IS_NULL_OPERATOR = 'isNull';

    private static Map<String, String> equalsOperator = new Map<String, String>{'value' => '=', 'label' => 'equals'};
    private static Map<String, String> notEqualToOperator = new Map<String, String>{'value' => '!=', 'label' => 'not equal to'};
    private static Map<String, String> startsWithOperator = new Map<String, String>{'value' => 'startsWith', 'label' => 'starts with'};
    private static Map<String, String> endsWithOperator = new Map<String, String>{'value' => 'endsWith', 'label' => 'ends with'};
    private static Map<String, String> containsOperator = new Map<String, String>{'value' => 'contains', 'label' => 'contains'};
    private static Map<String, String> doesNotContainOperator = new Map<String, String>{'value' => 'doesNotContain', 'label' => 'does not contain'};
    private static Map<String, String> lessThanOperator = new Map<String, String>{'value' => '<', 'label' => 'less than'};
    private static Map<String, String> greaterThanOperator = new Map<String, String>{'value' => '>', 'label' => 'greater than'};
    private static Map<String, String> lessOrEqualOperator = new Map<String, String>{'value' => '<=', 'label' => 'less or equal'};
    private static Map<String, String> greaterOrEqualOperator = new Map<String, String>{'value' => '>=', 'label' => 'greater or equal'};
    private static Map<String, String> isNullOperator = new Map<String, String>{'value' => IS_NULL_OPERATOR, 'label' => 'is null'};
    private static Map<String, String> includesOperator = new Map<String, String>{'value' => 'includes', 'label' => 'includes'};
    private static Map<String, String> excludesOperator = new Map<String, String>{'value' => 'excludes', 'label' => 'excludes'};

    public static String singleQuoteCode = '&apos;';

    public static Map<String, String> templatesBySpecialOperators = new Map<String, String>{
            startsWithOperator.get('value') => '({0} LIKE ' + singleQuoteCode + '{1}%' + singleQuoteCode + ')',
            endsWithOperator.get('value') => '({0} LIKE ' + singleQuoteCode + '%{1}' + singleQuoteCode + ')',
            containsOperator.get('value') => '({0} LIKE ' + singleQuoteCode + '%{1}%' + singleQuoteCode + ')',
            doesNotContainOperator.get('value') => '(NOT {0} LIKE ' + singleQuoteCode + '%{1}%' + singleQuoteCode + ')'
    };

    public static Map<String, List<Map<String, String>>> operatorNamesByDisplayTypes = new Map<String, List<Map<String, String>>>{
            'BOOLEAN' => new List<Map<String, String>>{
                    equalsOperator,
                    notEqualToOperator,
                    isNullOperator
            },
            'COMBOBOX' => new List<Map<String, String>>{
                    equalsOperator,
                    notEqualToOperator,
                    startsWithOperator,
                    endsWithOperator,
                    containsOperator,
                    doesNotContainOperator,
                    isNullOperator
            },
            'CURRENCY' => new List<Map<String, String>>{
                    equalsOperator,
                    notEqualToOperator,
                    lessThanOperator,
                    greaterThanOperator,
                    lessOrEqualOperator,
                    greaterOrEqualOperator,
                    isNullOperator
            },
            'DATE' => new List<Map<String, String>>{
                    equalsOperator,
                    notEqualToOperator,
                    lessThanOperator,
                    greaterThanOperator,
                    lessOrEqualOperator,
                    greaterOrEqualOperator,
                    isNullOperator
            },
            'DATETIME' => new List<Map<String, String>>{
                    equalsOperator,
                    notEqualToOperator,
                    lessThanOperator,
                    greaterThanOperator,
                    lessOrEqualOperator,
                    greaterOrEqualOperator,
                    isNullOperator
            },
            'DOUBLE' => new List<Map<String, String>>{
                    equalsOperator,
                    notEqualToOperator,
                    lessThanOperator,
                    greaterThanOperator,
                    lessOrEqualOperator,
                    greaterOrEqualOperator,
                    isNullOperator
            },
            'EMAIL' => new List<Map<String, String>>{
                    equalsOperator,
                    notEqualToOperator,
                    startsWithOperator,
                    endsWithOperator,
                    containsOperator,
                    doesNotContainOperator,
                    isNullOperator
            },
            'ENCRYPTEDSTRING' => new List<Map<String, String>>{
                    equalsOperator,
                    notEqualToOperator,
                    startsWithOperator,
                    endsWithOperator,
                    containsOperator,
                    doesNotContainOperator,
                    isNullOperator
            },
            'ID' => new List<Map<String, String>>{
                    equalsOperator,
                    notEqualToOperator,
                    isNullOperator
            },
            'INTEGER' => new List<Map<String, String>>{
                    equalsOperator,
                    notEqualToOperator,
                    lessThanOperator,
                    greaterThanOperator,
                    lessOrEqualOperator,
                    greaterOrEqualOperator,
                    isNullOperator
            },
            'LONG' => new List<Map<String, String>>{
                    equalsOperator,
                    notEqualToOperator,
                    lessThanOperator,
                    greaterThanOperator,
                    lessOrEqualOperator,
                    greaterOrEqualOperator,
                    isNullOperator
            },
            'MULTIPICKLIST' => new List<Map<String, String>>{
                    equalsOperator,
                    notEqualToOperator,
                    includesOperator,
                    excludesOperator,
                    isNullOperator
            },
            'PERCENT' => new List<Map<String, String>>{
                    equalsOperator,
                    notEqualToOperator,
                    lessThanOperator,
                    greaterThanOperator,
                    lessOrEqualOperator,
                    greaterOrEqualOperator,
                    isNullOperator
            },
            'PHONE' => new List<Map<String, String>>{
                    equalsOperator,
                    notEqualToOperator,
                    startsWithOperator,
                    endsWithOperator,
                    containsOperator,
                    doesNotContainOperator,
                    isNullOperator
            },
            'PICKLIST' => new List<Map<String, String>>{
                    equalsOperator,
                    notEqualToOperator,
                    startsWithOperator,
                    endsWithOperator,
                    containsOperator,
                    doesNotContainOperator,
                    isNullOperator
            },
            'REFERENCE' => new List<Map<String, String>>{
                    equalsOperator,
                    notEqualToOperator,
                    isNullOperator
            },
            'STRING' => new List<Map<String, String>>{
                    equalsOperator,
                    notEqualToOperator,
                    startsWithOperator,
                    endsWithOperator,
                    containsOperator,
                    doesNotContainOperator,
                    isNullOperator
            },
            'TIME' => new List<Map<String, String>>{
                    equalsOperator,
                    notEqualToOperator,
                    lessThanOperator,
                    greaterThanOperator,
                    lessOrEqualOperator,
                    greaterOrEqualOperator,
                    isNullOperator
            },
            'URL' => new List<Map<String, String>>{
                    equalsOperator,
                    notEqualToOperator,
                    startsWithOperator,
                    endsWithOperator,
                    containsOperator,
                    doesNotContainOperator,
                    isNullOperator
            },
            '__DEFAULT' => new List<Map<String, String>>{
                    equalsOperator,
                    notEqualToOperator,
                    isNullOperator
            }
    };
}