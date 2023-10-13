*** Settings ***
Documentation       Questo robot si occuperà di ordinare una sequenza di robot acquisita da un csv. Per ogni ordine salverà una ricevuta in pdf 
...                 ed infine creerà un archivio zip contenente tutte le ricevute. La ricevuta in pdf deve contenere uno screen con il preview del robot.

Library    RPA.Browser.Selenium    auto_close=${True}
Library    RPA.HTTP
Library    RPA.Tables
Library    RPA.PDF
Library    RPA.JavaAccessBridge
Library    RPA.FileSystem
Library    RPA.Archive

*** Tasks ***
Ordina robots su RobotSpareBin Industries
    Apri sito web RobotSpareBin e chiudi popup
    Scarica csv e invia il form per ogni riga in tabella
    Crea zip per report
    [Teardown]    Chiudi browser

*** Keywords ***
Apri sito web RobotSpareBin e chiudi popup
    Open Available Browser    https://robotsparebinindustries.com/    headless=${True}
    Click Link    xpath://*[@id="root"]/header/div/ul/li[2]/a
    Chiudi popup
    

Scarica csv e invia il form per ogni riga in tabella
    Download    https://robotsparebinindustries.com/orders.csv    overwrite=${True}
    ${ordini}=    Read table from CSV    orders.csv    header=${True}

    FOR    ${ordine}    IN    @{ordini}
        Select From List By Index    id:head    ${ordine}[Head]
        ${idBody}=    Catenate     SEPARATOR=   id-body-    ${ordine}[Body]
        RPA.Browser.Selenium.Click Element    id:${idBody}
        Input Text    xpath://html/body/div/div/div/div/div/form/div[3]/input   ${ordine}[Legs]
        Input Text    id:address    ${ordine}[Address]

        ${errore}   Set Variable    1
        WHILE    ${errore} > 0
            Click Button    id:order
            ${errore}=    Get Element Count    class:alert-danger
        END
        
        Wait Until Page Contains Element    id:receipt    30   
        Screenshot    id:robot-preview-image    ${OUTPUT_DIR}/preview-robot.png
        
        ${ricevuta}=    Get Element Attribute    id:receipt    outerHTML    
        ${nomePdfTemp}=    Catenate    SEPARATOR=    ${OUTPUT_DIR}/ricevute/Ricevuta    ${ordine}[Order number]    .pdf
        Html To Pdf    ${ricevuta}    ${nomePdfTemp}

        
        ${listaImmaginePdf}=    Create List    ${OUTPUT_DIR}/preview-robot.png

        Add Files To Pdf    ${listaImmaginePdf}    ${nomePdftemp}    append=${True}
         
        
        Click Button    id:order-another
        Chiudi popup
    END

Chiudi popup
        Wait Until Page Contains Element     xpath://html/body/div/div/div[2]/div/div/div/div/div/button[1]
        RPA.Browser.Selenium.Click Element     xpath://html/body/div/div/div[2]/div/div/div/div/div/button[1]

Crea zip per report
    Archive Folder With Zip    ${OUTPUT_DIR}/ricevute    ${OUTPUT_DIR}/Ricevute.zip

Chiudi browser
    Close Browser