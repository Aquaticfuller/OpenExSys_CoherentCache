import re
import copy

class check_resp:
    def __init__(self, core, lsu_id, port, info):
        self.core = core
        self.lsu_id = lsu_id
        self.port = port 
        self.info = info

class check_req:
    def __init__(self, core, lsu_id, port, info):
        self.core = core
        self.lsu_id = lsu_id
        self.port = port
        self.info = info
    def match(self, resp):
        if(self.core == resp.core and self.lsu_id == resp.lsu_id and self.port == resp.port):
            return True
        else:
            return False

class send_crd:
    def __init__(self, target, source, crd_id, channel, info):
        self.info = info
        self.target = target
        self.source = source
        self.crd_id = crd_id
        self.channel = channel

    def match(self, receiver):
        if(self.target == receiver.target and self.source == receiver.source and self.crd_id\
             == receiver.crd_id and self.channel == receiver.channel):
            return True
        else:
            return False

class receive_crd:
    def __init__(self, target, source, crd_id, channel, info):
        self.info = info
        self.target = target
        self.source = source
        self.crd_id = crd_id
        self.channel = channel

class receive_traffic:
    def __init__(self, target, source, vc_id, lar, flit, channel, info):
        self.info = info
        self.target = target
        self.source = source
        self.vc_id = vc_id
        self.flit = flit
        self.lar = lar
        self.channel = channel

class send_traffic:
    def __init__(self, target, source, vc_id, lar, flit, channel, info):
        self.info = info
        self.target = target
        self.source = source
        self.vc_id = vc_id
        self.flit = flit
        self.lar = lar
        self.channel = channel
    
    def match(self, receiver):
        if(self.channel != 'channel: 3'):
            if(self.target == receiver.target and self.source == receiver.source and self.vc_id\
             == receiver.vc_id and self.lar == receiver.lar and self.flit == receiver.flit and self.channel == receiver.channel):
                return True
            else:
                return False
        else:
            if(self.target == receiver.target and self.source == receiver.source and self.vc_id\
             == receiver.vc_id and self.lar == receiver.lar and self.flit[-9:] == receiver.flit[-9:] and self.channel == receiver.channel):
                return True
            else:
                return False




# 正则表达式模式
pattern_send_f = r'^.*(flit_sender).*$'
pattern_recei_f = r'^.*(flit_receiver).*$'
pattern_location = r'\(\w+,\s*\w+\)'
pattern_vcid = r'vc_id:\s*[0-9]'
pattern_lar = r'look_ahead_routing:\s*[0-9]'
pattern_flit = r'flit:\w+'
pattern_channel = r'channel:\s*\w'
pattern_crd_id = r'credit id:\s*\w'
pattern_send_c = r'^.*(crd_sender).*$'
pattern_recei_c = r'^.*(crd_receiver).*$'

# 输入文件名和输出文件名
input_file = 'run_1.log'
output_file = 'ebi_match.log'

# 打开输入文件和输出文件
se_list_f = []
re_list_f = []
se_list_c = []
re_list_c = []
st_req_list = []
st_resp_list = []
ld_req_list = []
ld_resp_list = []

with open(input_file, 'r') as f_in, open(output_file, 'w') as f_out:
    lines = f_in.readlines()
    i = 0
    while i < len(lines):
    # while i < 300000:
        if re.match(r'====================', lines[i].strip()):
            if re.match(r'^.*store req.*$', lines[i+1]):
                core = re.findall(r'core\s*[0-9]', lines[i+1])
                port = re.findall(r'port\s*[0-9]', lines[i+1])
                lsu_id = lines[i+2]
                info = ''
                i += 1
                while not re.match(r'====================', lines[i]):
                    info = info + lines[i]
                    i += 1
                ut = check_req(core[0], lsu_id, port, info)
                st_req_list.append(ut)
            if re.match(r'^.*load req.*$', lines[i+1]):
                core = re.findall(r'core\s*[0-9]', lines[i+1])
                port = re.findall(r'port\s*[0-9]', lines[i+1])
                lsu_id = lines[i+2]
                info = ''
                i += 1
                while not re.match(r'====================', lines[i]):
                    info = info + lines[i]
                    i += 1
                ut = check_req(core[0], lsu_id, port, info)
                ld_req_list.append(ut)
            if re.match(r'^.*store resp.*$', lines[i+1].strip()):
                core = re.findall(r'core\s*[0-9]', lines[i+1])
                port = re.findall(r'port\s*[0-9]', lines[i+1])
                lsu_id = lines[i+2]
                info = ''
                i += 1
                while not re.match(r'====================', lines[i]):
                    info += lines[i]
                    i += 1
                ut = check_resp(core[0], lsu_id, port, info)
                flag = False
                new_req_l = []
                for k in range(len(st_req_list)):
                    if ((not st_req_list[k].match(ut)) | flag): # only find the first one
                        new_req_l.append(st_req_list[k])
                    else:
                        flag = True
                st_req_list = copy.deepcopy(new_req_l)
                if(not flag):
                    st_resp_list.append(ut)
            if re.match(r'^.*load resp.*$', lines[i+1].strip()) or re.match(r'^.*load replay.*$', lines[i+1].strip()):
                core = re.findall(r'core\s*[0-9]', lines[i+1])
                port = re.findall(r'port\s*[0-9]', lines[i+1])
                lsu_id = lines[i+2]
                info = ''
                i += 1
                while not re.match(r'====================', lines[i]):
                    info += lines[i]
                    i += 1
                ut = check_resp(core[0], lsu_id, port, info)
                flag = False
                new_req_l = []
                for k in range(len(ld_req_list)):
                    if ((not ld_req_list[k].match(ut)) | flag): # only find the first one
                        new_req_l.append(ld_req_list[k])
                    else:
                        flag = True
                ld_req_list = copy.deepcopy(new_req_l)
                if(not flag):
                    ld_resp_list.append(ut)

        if re.match(pattern_send_f, lines[i].strip()):
            locations = re.findall(pattern_location, lines[i].strip())
            vcid = re.findall(pattern_vcid, lines[i].strip())
            lar = re.findall(pattern_lar, lines[i].strip())
            flit = re.findall(pattern_flit, lines[i].strip())
            chan = re.findall(pattern_channel, lines[i].strip())
            ut = send_traffic(locations[1], locations[0], vcid[0], lar[0], flit[0], chan[0], lines[i].strip())
            se_list_f.append(ut)

        if re.match(pattern_recei_f, lines[i].strip()):
            locations = re.findall(pattern_location, lines[i].strip())
            vcid = re.findall(pattern_vcid, lines[i].strip())
            lar = re.findall(pattern_lar, lines[i].strip())
            flit = re.findall(pattern_flit, lines[i].strip())
            chan = re.findall(pattern_channel, lines[i].strip())
            ut = receive_traffic(locations[0], locations[1], vcid[0], lar[0], flit[0], chan[0], lines[i].strip())
            flag = False
            new_se_l = []
            for k in range(len(se_list_f)):
                if ((not se_list_f[k].match(ut)) | flag): # only find the first one
                    new_se_l.append(se_list_f[k])
                else:
                    flag = True
            se_list_f = copy.deepcopy(new_se_l)
            if(not flag):
                re_list_f.append(ut)

        if re.match(pattern_send_c, lines[i].strip()):
            locations = re.findall(pattern_location, lines[i].strip())
            crd = re.findall(pattern_crd_id, lines[i].strip())
            chan = re.findall(pattern_channel, lines[i].strip())
            ut = send_crd(locations[1], locations[0], crd[0], chan[0], lines[i].strip())
            se_list_c.append(ut)

        if re.match(pattern_recei_c, lines[i].strip()):
            locations = re.findall(pattern_location, lines[i].strip())
            crd = re.findall(pattern_crd_id, lines[i].strip())
            chan = re.findall(pattern_channel, lines[i].strip())
            ut = receive_crd(locations[0], locations[1], crd[0], chan[0], lines[i].strip())
            flag = False
            new_se_l = []
            for k in range(len(se_list_c)):
                if ((not se_list_c[k].match(ut)) | flag):
                    new_se_l.append(se_list_c[k])
                else:
                    flag = True
            se_list_c = copy.deepcopy(new_se_l)
            if(not flag):
                re_list_c.append(ut)
        i += 1
    
    for ut in se_list_f:
        f_out.write(ut.info)
        f_out.write('\n')

    f_out.write(200*'*')
    f_out.write('\n')
    for ut in re_list_f:
        f_out.write(ut.info)
        f_out.write('\n')
    
    f_out.write(200*'*')
    f_out.write('\n')
    for ut in se_list_c:
        f_out.write(ut.info)
        f_out.write('\n')

    f_out.write(200*'*')
    f_out.write('\n')
    for ut in re_list_c:
        f_out.write(ut.info)
        f_out.write('\n')
    
    f_out.write(200*'*')
    f_out.write('\n')
    for ut in st_req_list:
        f_out.write(ut.info)
        f_out.write('\n')

    f_out.write(200*'*')
    f_out.write('\n')
    for ut in st_resp_list:
        f_out.write(ut.info)
        f_out.write('\n')

    f_out.write(200*'*')
    f_out.write('\n')
    for ut in ld_req_list:
        f_out.write(ut.info)
        f_out.write('\n')

    f_out.write(200*'*')
    f_out.write('\n')
    for ut in ld_resp_list:
        f_out.write(ut.info)
        f_out.write('\n')

