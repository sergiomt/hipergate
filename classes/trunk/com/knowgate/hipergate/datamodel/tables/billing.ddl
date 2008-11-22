CREATE TABLE k_accounts
(
    id_account       CHAR(10)     NOT NULL,			/* Identificador de la cuenta */
    tp_account       CHAR(1)      NOT NULL,			/* Tipo de cuenta ( P=Profesional, C=Corporativa, S=Sistema ) */
    id_domain        INTEGER      NOT NULL,			/* Dominio */
    dt_created       DATETIME     DEFAULT CURRENT_TIMESTAMP,    /* Fecha creación registro */
    bo_active        SMALLINT     DEFAULT 1,			/* Cuenta activa o no */
    max_users        INTEGER 	  DEFAULT 1,			/* Máximo número de usuarios permitido */
    sn_passport	     VARCHAR(16)  NOT NULL,			/* Nº de documento legal del contratante */
    tp_passport      CHAR(1)      NOT NULL,			/* Tipo de documento legal (DNI,NIF,CIF,...) */
    tp_billing       CHAR(1)      NOT NULL,    			/* Tipo de opción de cobro ( T=Tarjeta, B=Banco, ... ) */
    gu_billing_addr  CHAR(32)     NOT NULL,			/* GUID de k_addresses de la dirección de facturación */
    dt_modified      DATETIME     NULL, 			/* Fecha modificación del registro */
    dt_cancel        DATETIME     NULL,				/* Fecha de cancelación de la cuenta */
    gu_contact_addr  CHAR(32)     NULL,				/* GUID de k_addresses de la dirección de contacto */
    gu_workarea      CHAR(32)     NULL,				/* Workarea por defecto */
    gu_user          CHAR(32)     NULL,				/* Usuario Profesional o Usuario se promocionó desde cuenta gratuita */
    tx_name          VARCHAR(100) NULL,				/* Nombre */
    tx_surname1	     VARCHAR(100) NULL,				/* Apellido 1 */
    tx_surname2	     VARCHAR(100) NULL,				/* Apellido 2 */
    nm_company	     VARCHAR(50)  NULL,				/* Razón Social de la Empresa */
    de_title	     VARCHAR(50)  NULL, 			/* Cargo */
    id_gender	     CHAR(1)      NULL,
    dt_birth         DATETIME     NULL,
    nu_bank   	     CHAR(20)     NULL,				/* Nº de cuenta bancaria */
    nu_card          CHAR(16)     NULL,				/* Nº de la tarjeta */
    tp_card          VARCHAR(30)  NULL,				/* Tipo de la tarjeta ( MASTERCARD,VISA,AMEX,...) */
    tx_expire        VARCHAR(10)  NULL,				/* Fecha Expiración de la Tarjeta */
    nu_pin           VARCHAR(7)   NULL,				/* Pin de la Tarjeta */
    id_ref           VARCHAR(50)  NULL,				/* Referencia externa de la cuenta para enlace con otros sistemas */
    tx_comments      VARCHAR(254) NULL,				/* Comentarios */
    bo_trial         SMALLINT DEFAULT 1,  			/* Cuenta de prueba (bo_trial=1), cuenta de pago (bo_trial=0)*/

    CONSTRAINT pk_accounts PRIMARY KEY (id_account)
)
GO;
