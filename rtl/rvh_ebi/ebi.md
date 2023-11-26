# EBI
The external bus interface(EBI) serves as the off die data path to connect differnet tile.
## The following configurations can be configured:
1. PARITY_LENGTH: the length that a parity bit control
2. EBI_BUFFER_DEPTH: the depth of ebi's internal buffer
3. OFF_DIE_WD: the width of ebi data path
## Components:
1. ebi_pkg: the parameter of ebi
2. m1_ebi_if_handshake: it receives the inbound requests of master die, translating them to the message that m1_tx can transmitted. Besides, it translate receiving message from slave die to interface signal that can be received by master machine.
3. m1_tx: it is responsible for transmitting message
4. m1_rx: it is responsible for receiving message
## Ports:
| Name                            | Direction | Type                                  | Description                      |
| :------------------------------ | :-------- | :------------------------------------ | :------------------------------- |
| m1_m2_bus_o                     | out        | wire logic [OFF_DIE_WD-1:0]                           | send message to the opposite EBI                                 |
| m2_m1_credit_i                            | in        | wire logic                            |  receive the m1_m2_bus_o message's credit( serves as handshake signal)                           |
| m2_m1_bus_i                     | in        | wire logic [OFF_DIE_WD-1:0]                           | receive message from the opposite EBI                                 |
| m1_m2_credit_o                            |   out      | wire logic                            |  send the m2_m1_bus_i message's credit                          |