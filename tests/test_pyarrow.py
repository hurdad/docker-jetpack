import pyarrow as pa
import pyarrow.parquet as pq
import pyarrow.dataset as ds
import pyarrow.cuda as cuda
import numpy as np
import tempfile, os

def test_version():
    print(f"pyarrow version: {pa.__version__}")
    assert pa.__version__.startswith("15.")

def test_basic_array():
    arr = pa.array([1, 2, 3, 4, 5])
    assert len(arr) == 5
    assert arr.sum().as_py() == 15

def test_record_batch():
    batch = pa.record_batch({
        "x": pa.array([1.0, 2.0, 3.0]),
        "y": pa.array([4.0, 5.0, 6.0]),
    })
    assert batch.num_rows == 3
    assert batch.num_columns == 2

def test_parquet_roundtrip():
    table = pa.table({"a": [1, 2, 3], "b": ["x", "y", "z"]})
    with tempfile.TemporaryDirectory() as tmp:
        path = os.path.join(tmp, "test.parquet")
        pq.write_table(table, path)
        result = pq.read_table(path)
        assert result.equals(table)

def test_cuda_context():
    try:
        ctx = cuda.Context(0)
        print(f"  CUDA device 0 — free: {ctx.memory.free}, total: {ctx.memory.total}")
        assert ctx.memory.total > 0
    except cuda.CudaError:
        print("  SKIP  test_cuda_context (no GPU)")
        return

def test_cuda_buffer():
    try:
        ctx = cuda.Context(0)
        host = pa.array(np.arange(1024, dtype=np.int32))
        buf = cuda.CudaBuffer.from_buffer(host.buffers()[1])
        assert buf.size == host.buffers()[1].size
    except cuda.CudaError:
        print("  SKIP  test_cuda_buffer (no GPU)")
        return

if __name__ == "__main__":
    tests = [test_version, test_basic_array, test_record_batch,
             test_parquet_roundtrip, test_cuda_context, test_cuda_buffer]
    failed = 0
    for t in tests:
        try:
            t()
            print(f"  PASS  {t.__name__}")
        except Exception as e:
            print(f"  FAIL  {t.__name__}: {e}")
            failed += 1
    print(f"\n{len(tests) - failed}/{len(tests)} tests passed")
    exit(failed)
