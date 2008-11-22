CREATE TABLE k_user_pwds_info
(
    gu_user         CHAR(32) NOT NULL,
    id_domain	    INTEGER  NOT NULL, 
    tl_pwd          CHARACTER VARYING(100) NOT NULL,
    dt_created      DATETIME      DEFAULT CURRENT_TIMESTAMP,
    dt_modified     DATETIME      NULL,
    tx_nickname     VARCHAR(100)  NULL,
    tx_pwd          VARCHAR(50)   NULL, 
    tx_pwd_sign     VARCHAR(50)   NULL,
    tx_reply        VARCHAR(100)  NULL,
    dt_pwd_expires  DATETIME	  NULL,
    tx_email        CHARACTER VARYING(100) NULL,
    url_addr        CHARACTER VARYING(254) NULL,
    id_legal        VARCHAR(16)   NULL,
    tx_comments     VARCHAR(254)  NULL,
    tx_file         VARCHAR(250)  NULL,
    len_file        INTEGER       NULL,
    bin_file        LONGVARBINARY NULL,
    CONSTRAINT pk_user_pwds_info PRIMARY KEY (gu_user,id_domain,tl_pwd)
)    

CREATE TABLE k_user_banks_info
(
    gu_user         CHAR(32)    NOT NULL,
    id_domain	    INTEGER     NOT NULL, 
    nu_bank_acc     VARCHAR(28) NOT NULL,
    bo_active       SMALLINT    DEFAULT 1,
    tp_account      CHARACTER VARYING(30)  NULL,
    nm_bank         CHARACTER VARYING(50)  NULL,
    tx_addr         CHARACTER VARYING(254) NULL,
    nm_accholder    CHARACTER VARYING(100) NULL,
    im_credit_limit DECIMAL(14,4) NULL,
    de_bank_acc     VARCHAR(254)  NULL,
    CONSTRAINT pk_user_banks_info PRIMARY KEY (gu_user,id_domain,nu_bank_acc)
)

CREATE TABLE k_user_cards_info
(
    gu_user         CHAR(32)    NOT NULL,
    id_domain	    INTEGER     NOT NULL, 
    bo_active       SMALLINT    DEFAULT 1,
    nu_card         CHAR(16)    NULL,				/* Nº de la tarjeta */
    tp_card         VARCHAR(30) NULL,				/* Tipo de la tarjeta ( MASTERCARD,VISA,AMEX,...) */
    tp_billing      CHAR(1)      NULL,    			/* Tipo de opción de cobro (D=Debito, C=Credito, A=Aplazado ) */
    nm_cardholder	VARCHAR(100) NULL,				/* Titular de la cuenta o la tarjeta */
    tx_expire       VARCHAR(10)  NULL,				/* Fecha Expiración de la Tarjeta */
    nu_pin          VARCHAR(7)   NULL,				/* Pin de la Tarjeta */
    nu_cvv2         VARCHAR(4)   NULL,
    nu_bank_acc     VARCHAR(28) NULL,
    nm_bank         CHARACTER VARYING(50)  NULL,
    im_credit_limit DECIMAL(14,4) NULL,
    service_phone   VARCHAR(16)  NULL,
    de_card         VARCHAR(254)  NULL,
    CONSTRAINT pk_user_banks_info PRIMARY KEY (gu_user,id_domain,nu_bank_acc)
)
