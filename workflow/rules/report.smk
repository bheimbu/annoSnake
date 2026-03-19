rule report:
    output:
        "benchmark.html"
    localrule: True
    run:
        import pandas as pd
        from glob import glob

        dfs = []
        for f in glob("benchmarks/**/*.txt", recursive=True):
            rule_name = f.replace("benchmarks/", "").replace(".txt", "")
            df = pd.read_csv(f, sep="\t")
            df.insert(0, "rule", rule_name)
            dfs.append(df)

        combined = pd.concat(dfs).sort_values("s", ascending=False)

        # Summary stats
        total_wall   = combined["s"].sum()
        total_cpu    = combined["cpu_time"].sum()
        peak_rss     = combined["max_rss"].max()
        peak_vms     = combined["max_vms"].max()
        peak_uss     = combined["max_uss"].max()
        peak_pss     = combined["max_pss"].max()
        total_io_in  = combined["io_in"].sum()
        total_io_out = combined["io_out"].sum()
        total_jobs   = len(combined)

        def fmt_time(seconds):
            h = int(seconds // 3600)
            m = int((seconds % 3600) // 60)
            s = int(seconds % 60)
            return f"{h}h {m}m {s}s"

        def fmt_mb(mb):
            if mb >= 1024:
                return f"{mb/1024:.2f} GB"
            return f"{mb:.1f} MB"

        summary_html = f"""
        <table>
            <tr><th>Metric</th><th>Value</th></tr>
            <tr><td>Total jobs</td><td>{total_jobs}</td></tr>
            <tr><td>Total wall time</td><td>{fmt_time(total_wall)}</td></tr>
            <tr><td>Total CPU time</td><td>{fmt_time(total_cpu)}</td></tr>
            <tr><td>Peak memory RSS (Resident Set Size)</td><td>{fmt_mb(peak_rss)}</td></tr>
            <tr><td>Peak memory VMS (Virtual Memory Size)</td><td>{fmt_mb(peak_vms)}</td></tr>
            <tr><td>Peak memory USS (Unique Set Size)</td><td>{fmt_mb(peak_uss)}</td></tr>
            <tr><td>Peak memory PSS (Proportional Set Size)</td><td>{fmt_mb(peak_pss)}</td></tr>
            <tr><td>Total I/O in</td><td>{fmt_mb(total_io_in)}</td></tr>
            <tr><td>Total I/O out</td><td>{fmt_mb(total_io_out)}</td></tr>
        </table>
        """

        table_html = combined.to_html(index=False, float_format=lambda x: f"{x:.2f}")

        with open(output[0], "w") as fh:
            fh.write(f"""<html><head><title>Runtime Report</title>
            <style>
                body {{ font-family: sans-serif; padding: 2em; }}
                table {{ border-collapse: collapse; width: 100%; margin-bottom: 2em; }}
                th, td {{ border: 1px solid #ccc; padding: 8px; text-align: left; }}
                th {{ background: #f0f0f0; }}
                tr:nth-child(even) {{ background: #fafafa; }}
            </style></head>
            <body>
                <h1>Runtime Report</h1>
                <h2>Summary</h2>
                {summary_html}
                <h2>Per-rule Details</h2>
                {table_html}
            </body></html>""")