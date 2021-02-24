/*----------------------------------------------------------------------------------------------- */
/*                                                                                                */
/* This сlass converts the information into another special form.                                 */
/*                                                                                                */
/* METHODS AND CLASSES:                                                                           */
/* ENCODE:                       realizes text convertation.                                      */
/* SFDC_HTMLENCODE:              convert text to special HTML form.                               */
/* SFDC_JSENCODE:                convert text to special JS form.                                 */
/* SFDC_JSINHTMLENCODE:          convert JS text to special HTML form.                            */
/* SFDC_URLENCODE:               convert text to selected form.                                   */
/*                                                                                                */
/*------------------------------------------------------------------------------------------------*/

global with sharing class SFDCEncoder {
        
    private static final String[] HTML_DECODED  = new String[]{ 
        '&', 
        '<', 
        '>', 
        '"', 
        '\''
    };
    private static final String[] HTML_ENCODED  = new String[]{ 
        '&amp;', 
        '&lt;', 
        '&gt;', 
        '&quot;', 
        '&#39;' 
    };
    
    private static final String[] JSINHTML_DECODED = new String[] { 
        '&', 
        '\\', 
        '\'', 
        '"', 
        '\r', 
        '\n', 
        '<', 
        '>' 
    };
    private static final String[] JSINHTML_ENCODED = new String[] { 
        '&amp;', 
        '\\\\', 
        '\\\'', 
        '\\&quot;', 
        '\\r', 
        '\\n', 
        '&lt;', 
        '&gt;' 
    };

    private static final String[] JS_DECODED = new String[] { 
        '\\', 
        '\'', 
        '\n', 
        '\r', 
        '"', 
        '!--', 
        '/', 
        '<', 
        '>' 
    };
    private static final String[] JS_ENCODED = new String[] { 
        '\\\\', 
        '\\\'', 
        '\\n', 
        '\\r', 
        '\\"', 
        '\\!--', 
        '\\/', 
        '\\u003C', 
        '\\u003E' 
    };

    /*--------------------------------------------------------------------------------------------*/
    /*                                                                                            */
    /* METHOD: SFDC_encoder                                                                       */
    /*                                                                                            */
    /* This method realizes text convertation.                                                    */
    /*                                                                                            */
    /*--------------------------------------------------------------------------------------------*/

    private String ENCODE(String input, String[] fromArr, String[] toArr) {

        // return, if there is no text to convert
        if (input == null || input.length() == 0)
            return input;

        // convertation of information
        for (Integer i = 0; i < fromArr.size(); ++i) {
            input = input.replace(fromArr[i], toArr[i]);
        }
        
        return input;
    }

    /*--------------------------------------------------------------------------------------------*/
    /*                                                                                            */
    /* METHOD: SFDC_encoder                                                                       */
    /*                                                                                            */
    /* This method convert text to special HTML form.                                             */
    /*                                                                                            */
    /*--------------------------------------------------------------------------------------------*/

    global String SFDC_HTMLENCODE(String input) {
        return ENCODE(input, HTML_DECODED, HTML_ENCODED);
    }

    /*--------------------------------------------------------------------------------------------*/
    /*                                                                                            */
    /* METHOD: SFDC_encoder                                                                       */
    /*                                                                                            */
    /* This method convert text to special JS form.                                               */
    /*                                                                                            */
    /*--------------------------------------------------------------------------------------------*/

    global String SFDC_JSENCODE(String input) {
        return ENCODE(input, JS_DECODED, JS_ENCODED);
    }

    /*--------------------------------------------------------------------------------------------*/
    /*                                                                                            */
    /* METHOD: SFDC_encoder                                                                       */
    /*                                                                                            */
    /* This method convert JS text to special HTML form.                                          */
    /*                                                                                            */
    /*--------------------------------------------------------------------------------------------*/

    global String SFDC_JSINHTMLENCODE(String input) {
        return ENCODE(input, JSINHTML_DECODED, JSINHTML_ENCODED);
    }

    /*--------------------------------------------------------------------------------------------*/
    /*                                                                                            */
    /* METHOD: SFDC_encoder                                                                       */
    /*                                                                                            */
    /* This method convert text to UTF-8 form.                                                    */
    /*                                                                                            */
    /*--------------------------------------------------------------------------------------------*/

    global String SFDC_URLENCODE(String input) {
        return EncodingUtil.urlEncode(input, 'UTF-8');
    }

    /*--------------------------------------------------------------------------------------------*/
    /*                                                                                            */
    /* METHOD: SFDC_encoder                                                                       */
    /*                                                                                            */
    /* This method convert text to selected form.                                                 */
    /*                                                                                            */
    /*--------------------------------------------------------------------------------------------*/

    global String SFDC_URLENCODE(String input, String encoding) {
        return EncodingUtil.urlEncode(input, encoding);
    }
}