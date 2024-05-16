/*
 * brin_revmap.h
 *		Prototypes for BRIN reverse range maps
 *
 * Portions Copyright (c) 1996-2019, PostgreSQL Global Development Group
 * Portions Copyright (c) 1994, Regents of the University of California
 *
 * IDENTIFICATION
 *		src/include/access/brin_revmap.h
 */

#ifndef BRIN_REVMAP_H
#define BRIN_REVMAP_H

#include "access/brin_tuple.h"
#include "storage/block.h"
#include "storage/buf.h"
#include "storage/itemptr.h"
#include "storage/off.h"
#include "utils/relcache.h"
#include "utils/snapshot.h"


/*
 * In revmap pages, each item stores an ItemPointerData.  These defines let one
 * find the logical revmap page number and index number of the revmap item for
 * the given heap block number.
 */
#define HEAPBLK_TO_REVMAP_BLK(pagesPerRange, heapBlk) \
	((heapBlk / pagesPerRange) / REVMAP_PAGE_MAXITEMS)
#define HEAPBLK_TO_REVMAP_INDEX(pagesPerRange, heapBlk) \
	((heapBlk / pagesPerRange) % REVMAP_PAGE_MAXITEMS)

/*
 * GPDB: Similar to the above calculation, except we need to normalize the
 * provided heapBlk, with the starting block of the block sequence it belongs
 * to. Also, logical page numbers are 1-based.
 */
#define HEAPBLK_TO_REVMAP_PAGENUM_AO(pagesPerRange, heapBlk) \
	(((heapBlk - AOHeapBlockGet_startHeapBlock(heapBlk)) / pagesPerRange) / REVMAP_PAGE_MAXITEMS + 1)

/* struct definition lives in brin_revmap.c */
typedef struct BrinRevmap BrinRevmap;

extern BrinRevmap *brinRevmapInitialize(Relation idxrel,
										BlockNumber *pagesPerRange, Snapshot snapshot);
extern void brinRevmapTerminate(BrinRevmap *revmap);

extern void brinRevmapExtend(BrinRevmap *revmap,
							 BlockNumber heapBlk);
extern Buffer brinLockRevmapPageForUpdate(BrinRevmap *revmap,
										  BlockNumber heapBlk);
extern void brinSetHeapBlockItemptr(Buffer rmbuf, BlockNumber pagesPerRange,
									BlockNumber heapBlk, ItemPointerData tid);
extern BrinTuple *brinGetTupleForHeapBlock(BrinRevmap *revmap,
										   BlockNumber heapBlk, Buffer *buf, OffsetNumber *off,
										   Size *size, int mode, Snapshot snapshot);
extern bool brinRevmapDesummarizeRange(Relation idxrel, BlockNumber heapBlk);

/* GPDB specific */
extern void brinRevmapAOPositionAtStart(BrinRevmap *revmap, int seqNum);
extern void brinRevmapAOPositionAtEnd(BrinRevmap *revmap, int seqNum);

/*
 * GPDB: Given a 'heapBlk', return the starting block number of the range in
 * which 'heapBlk' lies.
 * Note: We have to factor in BlockSequence limits when we do this calculation.
 */
static inline BlockNumber
brin_range_start_blk(BlockNumber heapBlk, bool isAO, BlockNumber pagesPerRange)
{
	BlockNumber seqStartBlk = isAO ? AOHeapBlockGet_startHeapBlock(heapBlk) : 0;
	BlockNumber rangeNum = ((heapBlk - seqStartBlk) / pagesPerRange);

	return (rangeNum * pagesPerRange) + seqStartBlk;
}
#endif							/* BRIN_REVMAP_H */
