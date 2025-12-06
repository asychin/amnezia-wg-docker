import { Download } from 'lucide-react';
import { Button } from './ui/button';
import {
  Dialog,
  DialogContent,
  DialogDescription,
  DialogFooter,
  DialogHeader,
  DialogTitle,
} from './ui/dialog';

interface ConfigDialogProps {
  open: boolean;
  onOpenChange: (open: boolean) => void;
  clientName: string;
  configData: string;
  onDownload: () => void;
}

export function ConfigDialog({
  open,
  onOpenChange,
  clientName,
  configData,
  onDownload,
}: ConfigDialogProps) {
  return (
    <Dialog open={open} onOpenChange={onOpenChange}>
      <DialogContent className="max-w-2xl bg-white dark:bg-slate-800 border-slate-200 dark:border-slate-700 w-[calc(100%-2rem)] sm:max-w-2xl">
        <DialogHeader>
          <DialogTitle className="text-xl font-bold text-slate-900 dark:text-white">
            Конфигурация {clientName}
          </DialogTitle>
          <DialogDescription className="text-slate-500 dark:text-slate-400">
            WireGuard конфигурационный файл
          </DialogDescription>
        </DialogHeader>
        <div className="py-4">
          <pre className="bg-slate-50 dark:bg-slate-900 p-4 rounded-md overflow-auto text-xs border border-slate-200 dark:border-slate-700 text-slate-900 dark:text-slate-100 max-h-80">
            {configData}
          </pre>
        </div>
        <DialogFooter>
          <Button onClick={onDownload} className="w-full bg-blue-600 hover:bg-blue-700">
            <Download className="w-4 h-4 mr-2" />
            Скачать .conf
          </Button>
        </DialogFooter>
      </DialogContent>
    </Dialog>
  );
}
