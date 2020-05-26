--Cerinta 6. Vectori/VARRAY 
CREATE OR REPLACE PROCEDURE p_6 IS
        TYPE Patru IS VARRAY(4) OF VARCHAR2(15); 
  -- initializare
  echipa Patru := Patru('Ion', 'Maria', 'Andrei', 'Alex');
 
 PROCEDURE print_echipa (capul VARCHAR2) IS
  BEGIN
    DBMS_OUTPUT.PUT_LINE(capul);
    FOR i IN 1..4 LOOP
      DBMS_OUTPUT.PUT_LINE(i || '.' || echipa(i));
    END LOOP;
    DBMS_OUTPUT.PUT_LINE('    '); 
  END;
BEGIN 
  print_echipa('2017 Echipa:');
  echipa(2) := 'Ionela';  -- schimbam valoarea la doi
  echipa(4) := 'Mihai';
  print_echipa('2018 Echipa:');
  --  aduagam valori noi
  echipa := Patru('Alexandru', 'Mircea', 'Gabriel', 'Melania');
  print_echipa('2019 Echipa:');
END p_6;
/
--Apelare 6
exec p_6;

/
--Cerinta 7. Pretul unui produs dupa nume

CREATE OR REPLACE FUNCTION p_7 (
    device IN VARCHAR2
) RETURN FLOAT IS
    pretul NUMBER;
    CURSOR c1 IS
    SELECT
        pret
    FROM
        produs
    WHERE
        nume = device;
BEGIN
    OPEN c1;
    FETCH c1 INTO pretul;
    IF c1%notfound THEN
        pretul := -1;
    END IF;
    CLOSE c1;
    RETURN pretul;
END;
/
--Apelare 7
DECLARE
    nume produs.nume%TYPE :='S10';
BEGIN
    IF p_7(nume) = -1 THEN
        dbms_output.put_line('Produsul nu exista, asigurate ca ai scris corect.');
    ELSE
        dbms_output.put_line('Pretul produsului S10 este ' || p_7(nume));
    END IF;
END;
/

--Cerinta 8. Clientul afla in cate magazine se poate duce din orasul sau.
CREATE OR REPLACE FUNCTION p_8 (
    c_nume client.nume%TYPE
) RETURN NUMBER IS
    locuri adresa.oras%TYPE;
BEGIN
    SELECT
       COUNT(*)
    INTO locuri 
    FROM
        adresa
    join magazin on adresa.id_adresa = magazin.id_adresa
    WHERE
        adresa.oras = ( SELECT
                            adresa.oras
                        FROM
                            adresa
                        JOIN client on adresa.id_adresa = client.id_adresa
                        WHERE
                            client.nume = c_nume 
                      );
    RETURN locuri;
EXCEPTION
    WHEN no_data_found THEN
        raise_application_error(-20000, 'CLIENTUL NU EXISTA');
    WHEN too_many_rows THEN
        raise_application_error(-20001, 'ERORR ');
    WHEN OTHERS THEN
        raise_application_error(-20002, 'Alta eroare!');
END p_8;
/
-- Apelare 8
DECLARE
    nume client.nume%TYPE :='MIHAI';
BEGIN
    dbms_output.put_line('CLIENTUL '|| nume || ' SE POATE DUCE IN ' || p_8(nume));
END;
/
DECLARE
    nume client.nume%TYPE :='VRANCEANU1';
BEGIN
    dbms_output.put_line('CLIENTUL '|| nume || ' SE POATE DUCE IN ' || p_8(nume));
END;
/
--daca clientul nu se poate duce la magazinele din orasul sau nu exista clientul se va afisa 0 in count

--Cerinta 9 Clientul vrea sa stie numele furnizorul produsului comandat, daca are o singura comanda. Se considera ca fiecare furnizor are un nume, sau v-a intra in aceeasi eroare cu lipsa clienti in db.

CREATE OR REPLACE PROCEDURE p_9 (
    c_nume IN client.nume%TYPE,
    p_nume IN client.prenume%TYPE)
  AS
  de_la_cine furnizor.nume%TYPE;
BEGIN
    --sa adaug adresa
    
    SELECT furnizor.nume
    INTO de_la_cine 
    FROM furnizor
    WHERE id_furnizor = (
        SELECT produs.id_furnizor
        FROM produs
        WHERE produs.id_produs = (
            SELECT comanda_produs.id_produs
            FROM  comanda_produs
            WHERE  comanda_produs.id_comanda = (
                SELECT comanda.id_comanda
                FROM  comanda
                WHERE  comanda.id_client = (
                    SELECT client.id_client
                    FROM  client
                    WHERE  client.nume = c_nume AND client.prenume = p_nume
                )
            )
        )
    );
    dbms_output.put_line( de_la_cine );
EXCEPTION
    WHEN no_data_found THEN
        raise_application_error(-20000, 'Nu exista clientul/furnizorul in baza de date');
    WHEN too_many_rows THEN
        raise_application_error(-20001, 'Exista mai multi FURNIZORI');
    WHEN OTHERS THEN
        raise_application_error(-20002, 'Are mai multe comenzi');
END p_9;
/
--Apelare 9
ALTER PROCEDURE p_9 compile;
/
EXEC p_9('AURELIAN', 'GABRIEL');
/--- E OK
/
EXEC p_9('MIHAI', 'IONEL');
/---ARE MAI MULTE COMENZI
/
EXEC p_9('ION1', 'ION' );
/---NU ESTE INREGISTRAT
/
EXEC p_9('GIGEL', 'TOMA' );
/
--- NU EXISTA FURNIZORUL
/

--Cerinta 10, care permite insertul
SET SERVEROUTPUT ON;

CREATE OR REPLACE TRIGGER angajat_nou
BEFORE INSERT ON angajat
BEGIN
    DBMS_OUTPUT.PUT_LINE('Felicitari, inca un angajat in db');
END;
/
ALTER TRIGGER angajat_nou ENABLE;
/
ALTER TRIGGER angajat_nou DISABLE;
/
--Cerinta 10, care scoate eroare
SET SERVEROUTPUT ON;

CREATE OR REPLACE TRIGGER angajat_nu
BEFORE INSERT ON angajat
BEGIN
    RAISE_APPLICATION_ERROR(-20001,'nu mai angajam');
END;
/
ALTER TRIGGER am_angajat_nu ENABLE;
/
ALTER TRIGGER am_angajat_nu DISABLE;
/
--mai joi avem insertul de test, si stergerea 
INSERT INTO ANGAJAT
(ID_ANGAJAT, NUME, PRENUME, SALARIU, ZILE_CONCEDIU, DATA_ANGAJARE, ID_MAGAZIN)
VALUES 
(247, 'Alex', 'SILVIU', 4300, 21, TO_DATE('30/05/2020', 'DD/MM/YYYY'),106);
/
DELETE FROM ANGAJAT
WHERE
    ID_ANGAJAT = 247;
/
--Cerinta 11

CREATE OR REPLACE TRIGGER salariu_minim BEFORE
    UPDATE OF salariu ON angajat
    FOR EACH ROW
BEGIN
    IF ( :new.salariu < 2000 ) THEN
        raise_application_error(-20002, 'Nu ii poti diminua salariul sub 2000');
    END IF;
END;
/
--Declansare trigger la modificarea salariului unui angajat

UPDATE angajat
SET
    salariu = 1700
WHERE
    id_angajat = 129;
/
--Cerinta 12
/
show user;
/
--nu ai voie sa stergi o tabele
/
CREATE OR REPLACE TRIGGER securitate
    BEFORE DROP ON DATABASE
BEGIN
 raise_application_error(-20002, 'Nu ai voie sa stergi tabele');
END;
/
ALTER trigger securitate disable;
/
--creez tabele pentru test
 /
CREATE TABLE schema_audit_trg (
    data         VARCHAR2(20),
    operatiune   VARCHAR2(20),
    obiect_creat     VARCHAR2(20),
    obiect_nume      VARCHAR2(20)
);
/
-- actiune care declansaeza triggerul

DROP TABLE schema_audit_trg;
/