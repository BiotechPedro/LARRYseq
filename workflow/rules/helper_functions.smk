from pathlib import Path
import os 
import sys

# wildcard constraints to be sure that output names are defined properly
wildcard_constraints:
    # hamming distance can just be a value
    hd=r"\d+",
    # LARRY fastqs corresponding to cellular barcode and feature barcode can only be R1 or R2
    read_fb="R[1|2]",
    read_cb="R[1|2]",
    # lib type can be just ATAC, GEX or FB
    lib_type='|'.join([x for x in ["ATAC", "GEX", "FB", "CH"]])


# Input functions
# --------------------------------------------------------------------------------
def get_fastqs(wildcards):
    """Return all FASTQS specified in sample metadata."""
    return units.loc[(wildcards.sample, wildcards.lib_type, wildcards.lane), ["R1", "R2"]].dropna()


# Other helper functions
# --------------------------------------------------------------------------------
def get_mem_mb(base_memory, step):
    def mem(wildcards, attempt):
        return base_memory + (step * (attempt - 1))
    return mem


def is_feature_bc():
    """Specify whether feature barcoding has been performed
    or not
    """
    if LARRY["feature_bc"]:
        return True
    else:
        return False

