/*----------------------------------------------------------------------------------------------- */
/*                                                                                                */
/* This class this class provides total access to SFDCEncoder and SFDCSecurityUtils.              */
/*                                                                                                */
/* METHODS AND CLASSES:                                                                           */
/* encoder:                         creates SFDCEncoder object for using it's methods.            */
/* securityUtils:                   creates SFDCSecurityUtils object for using it's methods.      */
/*                                                                                                */
/*------------------------------------------------------------------------------------------------*/

global with sharing class ESAPI {   

    private static SFDCEncoder SFDC_encoder;
    private static SFDCSecurityUtils SFDC_validator;

    /*--------------------------------------------------------------------------------------------*/
    /*                                                                                            */
    /* METHOD: SFDC_encoder                                                                       */
    /*                                                                                            */
    /* This method creates SFDCEncoder object for using it's methods.                             */
    /*                                                                                            */
    /*--------------------------------------------------------------------------------------------*/

    public static SFDCEncoder encoder() {
        return (SFDC_encoder == null) ? new SFDCEncoder() : SFDC_encoder;
    }

    /*--------------------------------------------------------------------------------------------*/
    /*                                                                                            */
    /* METHOD: securityUtils                                                                      */
    /*                                                                                            */
    /* This method creates SFDCSecurityUtils object for using it's methods.                       */
    /*                                                                                            */
    /*--------------------------------------------------------------------------------------------*/

    public static SFDCSecurityUtils securityUtils() {
        return (SFDC_validator == null) ? new SFDCSecurityUtils() : SFDC_validator;
    }
}