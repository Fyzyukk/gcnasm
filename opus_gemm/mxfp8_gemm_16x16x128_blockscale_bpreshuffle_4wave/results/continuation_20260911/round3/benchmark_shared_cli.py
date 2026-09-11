"""Kernel timings through the C ABI; every library reuses identical tensors.

The generated inputs exactly reproduce the standalone CLI seed=1 pattern. Each candidate is
checked at full 8192-cubed against the separately validated baseline.
No input transform, allocation, reference work or comparison is timed.
"""
import ctypes,datetime,hashlib,json,os,pathlib,statistics,subprocess,sys,threading,time
os.environ.setdefault('HIP_VISIBLE_DEVICES','5')
os.environ['OMP_TOOL']='disabled'
os.environ['OMP_NUM_THREADS']='16'
expected_pci=os.environ.get('MXFP8_EXPECTED_PCI','0000:85:00.0').lower()
status_before=json.loads(subprocess.check_output(['rocm-smi','--showbus','--showuse','--showmemuse','--json'],text=True))
physical_card,card_status=next((name,value) for name,value in status_before.items() if value.get('PCI Bus','').lower()==expected_pci)
max_initial_vram=int(os.environ.get('MXFP8_MAX_INITIAL_VRAM_PERCENT','1'))
assert int(card_status['GPU use (%)'])<=5 and int(card_status['GPU Memory Allocated (VRAM%)'])<=max_initial_vram,card_status
import torch

root=pathlib.Path(__file__).resolve().parent
work=pathlib.Path(os.environ.get('MXFP8_WORK_DIR') or (root/'work_path.txt').read_text().strip())
base=work/'baseline'
rounds=int(os.environ.get('MXFP8_SHARED_ROUNDS','3'))
bracketed=os.environ.get('MXFP8_BRACKETED','0')=='1'
telemetry_enabled=os.environ.get('MXFP8_TELEMETRY','0')=='1'
native_timing=os.environ.get('MXFP8_NATIVE_TIMING','0')=='1'
hip=ctypes.CDLL('/opt/rocm/lib/libamdhip64.so')
pci_buffer=ctypes.create_string_buffer(64)
assert hip.hipDeviceGetPCIBusId(pci_buffer,64,0)==0
actual_pci=pci_buffer.value.decode().lower()
assert actual_pci==expected_pci
print('Shared-address comparison on PCI',actual_pci,flush=True)
sys.path.insert(0,str(base))
from blockscale_bpreshuffle import _Args
if native_timing:
 native_lib=ctypes.CDLL(str(root/'support/native_benchmark.so'))
 native_fn=native_lib.benchmark_mxfp8_launches
 native_fn.argtypes=[ctypes.c_void_p,ctypes.POINTER(_Args),ctypes.c_int,ctypes.c_void_p,ctypes.c_int,ctypes.c_int,ctypes.POINTER(ctypes.c_float)]
 native_fn.restype=ctypes.c_int
tag=sys.argv[1]; names=['baseline']+[name for name in sys.argv[2:] if name!='baseline']
dest=root/'shared_allocations'/tag;dest.mkdir(parents=True,exist_ok=False)
torch.set_num_threads(16);torch.manual_seed(20260911)
torch.cuda.set_device(0)
m=n=k=8192
generator=ctypes.CDLL(str(root/'support/cli_input_generator.so'))
for fn in [generator.make_fp8,generator.make_scale]:
 fn.argtypes=[ctypes.c_void_p,ctypes.c_size_t,ctypes.c_uint64]
 fn.restype=None
def filled(shape,seed,scale=False):
 host=torch.empty(shape,dtype=torch.uint8)
 fn=generator.make_scale if scale else generator.make_fp8
 fn(ctypes.c_void_p(host.data_ptr()),host.numel(),seed)
 return host.cuda()
a=filled((m,k),1).view(torch.float8_e4m3fn)
raw_b=filled((n,k),1^0x3141592653589793).view(torch.float8_e4m3fn)
b=raw_b.view(n//16,16,k//32,2,16).permute(0,2,3,1,4).contiguous().view(n,k)
sa=filled((k//128,m),1^0x2718281828459045,True)
sb=filled((n//128,k//128),1^0x6a09e667f3bcc909,True)
del raw_b
outputs={'bf16':torch.empty((m,n),device='cuda',dtype=torch.bfloat16),'fp32':torch.empty((m,n),device='cuda',dtype=torch.float32)}
torch.cuda.synchronize()
libs={};pointers={};metadata={}
for name in names:
 d=work/name
 lib=ctypes.CDLL(str(d/'build/libblockscale_bpreshuffle.so'),mode=ctypes.RTLD_LOCAL)
 fn=lib.launch_blockscale_bpreshuffle
 fn.argtypes=[ctypes.POINTER(_Args),ctypes.c_int,ctypes.c_int,ctypes.c_void_p]
 fn.restype=ctypes.c_int
 libs[name]=(lib,fn)
 metadata[name]={'path':str(d),'source_sha256':hashlib.sha256((d/'tmpl.hpp').read_bytes()).hexdigest(),'library_sha256':hashlib.sha256((d/'build/libblockscale_bpreshuffle.so').read_bytes()).hexdigest()}
stream=ctypes.c_void_p(torch.cuda.current_stream().cuda_stream)
for dtype,c in outputs.items():
 args=_Args(a.data_ptr(),b.data_ptr(),c.data_ptr(),m,n,k,1,k,k,n,m*k,n*k,m*n,sa.data_ptr(),sb.data_ptr(),m,k//128,m*(k//128),(n//128)*(k//128))
 pointers[dtype]=(args,ctypes.byref(args),int(dtype=='bf16'))
(dest/'metadata.json').write_text(json.dumps(dict(gpu=torch.cuda.get_device_name(),physical_card=physical_card,hip_visible_devices=os.environ['HIP_VISIBLE_DEVICES'],pci=actual_pci,comparison_scope='Contemporaneous same-device, same-tensor-address comparison; report this card and this run baseline',timestamp_utc=datetime.datetime.now(datetime.timezone.utc).isoformat(),initial_device_status=card_status,shape=[m,n,k],batch=1,warmup=200,iterations=100,rounds=rounds,versions=metadata,pointers={'A':a.data_ptr(),'B':b.data_ptr(),'SFA':sa.data_ptr(),'SFB':sb.data_ptr(),**{k:v.data_ptr() for k,v in outputs.items()}},input_pattern='Exact CLI seed=1 generator and host FP8 type',timing='HIP events around 100 C ABI launches, no preprocessing',bracketed=bracketed,telemetry_enabled=telemetry_enabled,native_timing=native_timing,benchmark_helper_sha256=hashlib.sha256((root/'support/native_benchmark.so').read_bytes()).hexdigest() if native_timing else None),indent=2)+'\n')
# Exact equality to the separately validated baseline is meaningful here:
# each accumulator sees identical FP8/E8M0 operands in the same K order.
# Independent full-shape dequantized reference was checked in the dyadic run.
reference_outputs={}
for name in names:
 for dtype,out in outputs.items():
  args,ptr,flag=pointers[dtype]
  out.fill_(float('nan'))
  assert libs[name][1](ptr,flag,1,stream)==0
  torch.cuda.synchronize()
  if name=='baseline':
   reference_outputs[dtype]=out.clone()
  else:
   torch.testing.assert_close(out,reference_outputs[dtype],rtol=0,atol=0)
  print(f'FULL_BASELINE_EQUAL {name} {dtype} {m*n} outputs',flush=True)

events=(torch.cuda.Event(enable_timing=True),torch.cuda.Event(enable_timing=True))
records=[]
telemetry=[]
telemetry_stop=threading.Event()
def sample_device():
 while not telemetry_stop.is_set():
  started=datetime.datetime.now(datetime.timezone.utc).isoformat()
  proc=subprocess.run(['rocm-smi','--device',physical_card.removeprefix('card'),'--showbus','--showuse','--showmemuse','--showclocks','--showpower','--showtemp','--json'],capture_output=True,text=True)
  telemetry.append(dict(timestamp_utc=started,returncode=proc.returncode,status=json.loads(proc.stdout) if proc.returncode==0 else proc.stderr))
  telemetry_stop.wait(0.10)
if telemetry_enabled:
 telemetry_thread=threading.Thread(target=sample_device,daemon=True)
 telemetry_thread.start()
for round_index in range(rounds):
 order=names if round_index%2==0 else names[::-1]
 if bracketed:
  plan=[(name,dtype,candidate,role) for dtype in outputs for candidate in order if candidate!='baseline' for name,role in [('baseline','before'),(candidate,'candidate'),('baseline','after')]]
 else:
  plan=[(name,dtype,None,None) for name in order for dtype in outputs]
 for name,dtype,comparison,role in plan:
  fn=libs[name][1]
  args,ptr,flag=pointers[dtype]
  started=datetime.datetime.now(datetime.timezone.utc).isoformat()
  if native_timing:
   result_ms=ctypes.c_float()
   status=native_fn(ctypes.cast(fn,ctypes.c_void_p),ptr,flag,stream,200,100,ctypes.byref(result_ms))
   if status:raise RuntimeError(status)
   ms=result_ms.value
  else:
   for _ in range(200):
    status=fn(ptr,flag,1,stream)
    if status:raise RuntimeError(status)
   events[0].record()
   for _ in range(100):
    status=fn(ptr,flag,1,stream)
    if status:raise RuntimeError(status)
   events[1].record();events[1].synchronize()
   ms=events[0].elapsed_time(events[1])/100
  row=dict(round=round_index+1,name=name,dtype=dtype,ms=ms,pflops=2*m*n*k/(ms*1e12),start_utc=started,timestamp_utc=datetime.datetime.now(datetime.timezone.utc).isoformat(),comparison=comparison,role=role)
  records.append(row)
  (dest/'records.json').write_text(json.dumps(records,indent=2)+'\n')
  print(f'{round_index+1} {name} {dtype}: {ms:.9f} ms / {row["pflops"]:.6f} P',flush=True)
if telemetry_enabled:
 telemetry_stop.set();telemetry_thread.join(timeout=5)
 (dest/'telemetry.json').write_text(json.dumps(telemetry,indent=2)+'\n')
if bracketed:
 comparisons=[]
 for i in range(0,len(records),3):
  before,candidate,after=records[i:i+3]
  reference_ms=(before['ms']+after['ms'])/2
  comparisons.append(dict(round=candidate['round'],name=candidate['name'],dtype=candidate['dtype'],candidate_ms=candidate['ms'],baseline_before_ms=before['ms'],baseline_after_ms=after['ms'],reference_ms=reference_ms,speedup_percent=100*(reference_ms/candidate['ms']-1),baseline_drift_percent=100*(after['ms']/before['ms']-1)))
 (dest/'bracketed_comparisons.json').write_text(json.dumps(comparisons,indent=2)+'\n')
summary=[]
for name in names:
 for dtype in outputs:
  vals=[r['ms'] for r in records if r['name']==name and r['dtype']==dtype]
  ms=statistics.median(vals)
  summary.append(dict(name=name,dtype=dtype,median_ms=ms,min_ms=min(vals),max_ms=max(vals),median_pflops=2*m*n*k/(ms*1e12)))
(dest/'summary.json').write_text(json.dumps(summary,indent=2)+'\n')
print(json.dumps(summary,indent=2),flush=True)
