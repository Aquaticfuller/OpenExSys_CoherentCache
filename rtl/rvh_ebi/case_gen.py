import math

com_case = ''
uncom_case = ''

DATA_BURST_NUM = 8

for i in range(2**DATA_BURST_NUM):
    com_case += "{}\'b".format(DATA_BURST_NUM) + "{:0>{}}:".format(bin(i)[2:], DATA_BURST_NUM) + " begin\n"
    current_bit = 0
    case_num = i
    valid_count = 0
    while case_num:
        if (case_num%2):
            com_case += "\tdata_com_r[DATA_LENGTH_PER_PKG*{} +: DATA_LENGTH_PER_PKG] = data_uncom[DATA_LENGTH_PER_PKG*{} +: DATA_LENGTH_PER_PKG];\n".format(valid_count, current_bit)
            valid_count += 1
        case_num >>= 1
        current_bit += 1
    com_case += "\tvalid_counter_r = {}'d{};\nend\n".format(math.ceil(math.log2(DATA_BURST_NUM)) + 1, valid_count)

for i in range(2**DATA_BURST_NUM):
    uncom_case += "{}\'b".format(DATA_BURST_NUM) + "{:0>{}}:".format(bin(i)[2:], DATA_BURST_NUM) + " begin\n"
    current_bit = 0
    case_num = i
    valid_count = 0
    while case_num:
        if (case_num%2):
            uncom_case += "\tdata_uncom_r[DATA_LENGTH_PER_PKG*{} +: DATA_LENGTH_PER_PKG] = data_com[DATA_LENGTH_PER_PKG*{} +: DATA_LENGTH_PER_PKG];\n".format(current_bit, valid_count)
            valid_count += 1
        case_num >>= 1
        current_bit += 1
    uncom_case += "end\n"


# print(com_case)
print(uncom_case)